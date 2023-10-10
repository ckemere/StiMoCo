//
//  ContentView.swift
//  BLEScanner
//
//  Created by Christian Möller on 02.01.23.
//

import SwiftUI
import CoreBluetooth


private struct ModuleUUIDs {
    static let ModuleParamsService = CBUUID(string: "5F9B2DB5-88F0-41E0-99A0-0DF2A49F5DB9")
    static let PeriodCharactersticUUID = CBUUID(string:"00000000-0000-1000-8000-00805F9B34F1")
    static let CurrentCharactersticUUID = CBUUID(string:"00000000-0000-1000-8000-00805F9B34F2")
    static let UptimeCharactersticUUID = CBUUID(string:"00000000-0000-1000-8000-00805F9B34F3")
}


struct StimParameters:Equatable {
    var period: UInt16 = 0
    var current: UInt8 = 0
    var frequency: Int = 0
}

struct DataFreshness {
    var uptime = false
    var period = false
    var current = false
}

struct UpdateFreshness {
    var period = true
    var current = true
}


// Stuff related to connecting to a selected individual module
enum ConnectionState {
    case not_connected, waiting_for_connection, connected, disconnected
}
enum ScanningState {
    case not_connected, retrieving_services, retrieving_characteristics, querying_characteristics, module_updated
}


// Class to interface with discovered peripherals
class DiscoveredPeripheral: NSObject, CBPeripheralDelegate, ObservableObject {
    @Published var moduleID: UInt8
    @Published var rssi: Int
    var peripheral: CBPeripheral
    
//    @Binding var bleManager: CBCentralManager
    
    @Published var connectionState: ConnectionState = ConnectionState.not_connected
    @Published var scanningState: ScanningState = ScanningState.not_connected

    
    // Data received from BLE characteristics
    @Published var stimParameters: StimParameters = StimParameters() {
        didSet {
            print(stimParameters)
        }
    }
    @Published var uptime: UInt32 = 0
    
    var dataFreshness: DataFreshness = DataFreshness()
    @Published var updateFreshness : UpdateFreshness = UpdateFreshness()
    
    private var moduleService: CBService?
    private var moduleUptimeCharacteristic: CBCharacteristic?
    private var moduleCurrentCharacteristic: CBCharacteristic?
    private var modulePeriodCharacteristic: CBCharacteristic?

    
    init(peripheral: CBPeripheral, moduleID: UInt8, rssi: Int) {
        self.peripheral = peripheral
        self.moduleID = moduleID
        self.rssi = Int(rssi)
        super.init()
    }
    
    func discoverModuleService() {
        if (connectionState == ConnectionState.connected) {
            print("Discovering services")
            peripheral.discoverServices([ModuleUUIDs.ModuleParamsService])
            scanningState = ScanningState.retrieving_services
        }
        else {
            print("Not sure how we are discovering when disconnected")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
//                print("Found service \(service)")
                if service.uuid == ModuleUUIDs.ModuleParamsService {
                    moduleService = service
                }
            }
        }
        
        self.discoverModuleCharacteristics()
    }
    
    func discoverModuleCharacteristics() {
        if (connectionState == ConnectionState.connected) {
            self.peripheral.discoverCharacteristics(nil, for: moduleService!) // should maybe list our UUIDs?
            scanningState = ScanningState.querying_characteristics
        }
        else {
            print("Not sure how we got here.")
        }
    }

    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard service.characteristics != nil else {
            print("No characteristics found for service: \(service)")
            return
        }
                
        for characteristic in service.characteristics ?? [] {
//            print("Found characteristic: \(characteristic)")
            
            switch characteristic.uuid {
            case ModuleUUIDs.CurrentCharactersticUUID:
                moduleCurrentCharacteristic = characteristic
            case ModuleUUIDs.PeriodCharactersticUUID:
                modulePeriodCharacteristic = characteristic
            case ModuleUUIDs.UptimeCharactersticUUID:
                moduleUptimeCharacteristic = characteristic
            default:
                break
            }
        }
        
        queryModuleData()
    }
        
    func queryModuleData() {
        guard connectionState == ConnectionState.connected else {
            print("Not sure how we got here.")
            return
        }
        guard let periodCharacteristic = modulePeriodCharacteristic,
              let currentCharacteristic = moduleCurrentCharacteristic,
              let uptimeCharacteristic = moduleUptimeCharacteristic  else {
            print("Error: one of our characteristics is is nil")
            return
        }
        
        if (!dataFreshness.uptime) {
            peripheral.readValue(for: uptimeCharacteristic)
            scanningState = ScanningState.retrieving_characteristics
        }
        else if (!dataFreshness.current) {
            peripheral.readValue(for: currentCharacteristic)
            scanningState = ScanningState.retrieving_characteristics
        }
        else if (!dataFreshness.period) {
            peripheral.readValue(for: periodCharacteristic)
            scanningState = ScanningState.retrieving_characteristics
        }
    }
    
    func requery_module() {
        dataFreshness.uptime = false;
        dataFreshness.current = false;
        dataFreshness.period = false;
        
        queryModuleData()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else {
            print("No data received in characteristic")
            return
        }
        print("Value recevied for characteristic: \(characteristic)")

        switch characteristic.uuid {
        case ModuleUUIDs.CurrentCharactersticUUID:
            guard let bytedata = data.first else {
                print("No data received for current")
                return
            }
            stimParameters.current = bytedata
            print(stimParameters.current)
            dataFreshness.current = true;

        case ModuleUUIDs.PeriodCharactersticUUID:
            guard data.count == 2 else {
                print("Weird size received for period")
                return
            }
            (data as NSData).getBytes(&stimParameters.period, length: MemoryLayout<UInt16>.size)
            stimParameters.frequency = Int(32768/stimParameters.period)
            dataFreshness.period = true;

        case ModuleUUIDs.UptimeCharactersticUUID:
            guard data.count == 4 else {
                print("Weird size received for uptime")
                return
            }
            (data as NSData).getBytes(&uptime, length: MemoryLayout<UInt32>.size)
            dataFreshness.uptime = true;
        default:
            break
        }
        
        if (dataFreshness.uptime) && (dataFreshness.period) && (dataFreshness.current) {
            scanningState = ScanningState.module_updated
        }
        else {
            queryModuleData()
        }
    
    }

    func updateFrequency(new_frequency: Int) {
        guard connectionState == ConnectionState.connected else {
            print("Not sure how we got here.")
            return
        }
        guard let periodCharacteristic = modulePeriodCharacteristic else {
            print("Error: period characteristic is nil")
            return
        }
        
        var value = UInt32(32768.0 / Float(new_frequency))
        
        let ns = NSData(bytes: &value, length: MemoryLayout<UInt16>.size)
        peripheral.writeValue(ns as Data, for: periodCharacteristic, type: .withResponse)
        
        updateFreshness.period = false
    }
    
    func updateCurrent(new_current: UInt8) {
        guard connectionState == ConnectionState.connected else {
            print("Not sure how we got here.")
            return
        }
        guard let currentCharacteristic = moduleCurrentCharacteristic else {
            print("Error: current characteristic is nil")
            return
        }
        
        var value = new_current
        
        let ns = NSData(bytes: &value, length: MemoryLayout<UInt8>.size)
        peripheral.writeValue(ns as Data, for: currentCharacteristic, type: .withResponse)
        
        updateFreshness.current = false
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("Value recevied for characteristic: \(characteristic)")

        switch characteristic.uuid {
        case ModuleUUIDs.CurrentCharactersticUUID:
            updateFreshness.current = true;

        case ModuleUUIDs.PeriodCharactersticUUID:
            updateFreshness.period = true;
            
        default:
            break
        }
    }
    
    
}

class BluetoothManager: NSObject, CBCentralManagerDelegate, ObservableObject {
    @Published var discoveredPeripherals = [DiscoveredPeripheral]()
    @Published var isScanning = false
    var centralManager: CBCentralManager!
    // Set to store unique peripherals that have been discovered
    var discoveredPeripheralSet = Set<CBPeripheral>()
    var timer: Timer?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func startScan() {
        if centralManager.state == .poweredOn {
            // Set isScanning to true and clear the discovered peripherals list
            isScanning = true
            discoveredPeripherals.removeAll()
            discoveredPeripheralSet.removeAll()
            objectWillChange.send()

            // Start scanning for peripherals
            centralManager.scanForPeripherals(withServices: [ModuleUUIDs.ModuleParamsService])

            // Start a timer to stop and restart the scan every 2 seconds
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] timer in
                self?.centralManager.stopScan()
                self?.centralManager.scanForPeripherals(withServices: [ModuleUUIDs.ModuleParamsService])
            }
        }
    }

    func stopScan() {
        // Set isScanning to false and stop the timer
        isScanning = false
        timer?.invalidate()
        centralManager.stopScan()
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            //print("central.state is .unknown")
            stopScan()
        case .resetting:
            //print("central.state is .resetting")
            stopScan()
        case .unsupported:
            //print("central.state is .unsupported")
            stopScan()
        case .unauthorized:
            //print("central.state is .unauthorized")
            stopScan()
        case .poweredOff:
            //print("central.state is .poweredOff")
            stopScan()
        case .poweredOn:
            //print("central.state is .poweredOn")
            startScan()
        @unknown default:
            print("central.state is unknown")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        // Build a string representation of the advertised data and sort it by names
        var advertisedData = advertisementData.map { "\($0): \($1)" }.sorted(by: { $0 < $1 }).joined(separator: "\n")

        // Convert the timestamp into human readable format and insert it to the advertisedData String
        let timestampValue = advertisementData["kCBAdvDataTimestamp"] as! Double
        // print(timestampValue)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let dateString = dateFormatter.string(from: Date(timeIntervalSince1970: timestampValue))

//        advertisedData = "actual rssi: \(RSSI) dB\n" + "Timestamp: \(dateString)\n" + advertisedData
        
        var moduleID = UInt8(255)
        if let manufacturerData = advertisementData["kCBAdvDataManufacturerData"] as? Data {
            assert(manufacturerData.count >= 3)
            moduleID = UInt8(manufacturerData[2])
        }
        
        // If the peripheral is not already in the list
        if !discoveredPeripheralSet.contains(peripheral) {
            // Add it to the list and the set
            discoveredPeripherals.append(DiscoveredPeripheral(peripheral: peripheral,
                                                              moduleID: moduleID,
                                                              rssi: Int(RSSI)))
            discoveredPeripheralSet.insert(peripheral)
            objectWillChange.send()
        } else {
            // If the peripheral is already in the list, update its advertised data
            if let index = discoveredPeripherals.firstIndex(where: { $0.peripheral == peripheral }) {
                discoveredPeripherals[index].moduleID = moduleID
                discoveredPeripherals[index].rssi = Int(RSSI)
                objectWillChange.send()
            }
        }
    }

    func connectToDevice(module: DiscoveredPeripheral) {
        print("Trying to connect \(module.peripheral.name)")

        module.connectionState = ConnectionState.waiting_for_connection
        centralManager.connect(module.peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Did connect triggered, \(peripheral.name)")
        
        if !discoveredPeripheralSet.contains(peripheral) {
            // Add it to the list and the set
            print("Unexpected connection from \(peripheral)")
        } else {
            // If the peripheral is already in the list, update its advertised data
            if let index = discoveredPeripherals.firstIndex(where: { $0.peripheral == peripheral }) {
                let module = discoveredPeripherals[index]
                module.peripheral.delegate = module
                module.connectionState = ConnectionState.connected
                objectWillChange.send()
                // Call module scan!
                module.discoverModuleService()
            }
        }

    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Did fail to connect triggered.")
        
        if !discoveredPeripheralSet.contains(peripheral) {
            // Add it to the list and the set
            print("Unexpected failed connection from \(peripheral)")
        } else {
            // If the peripheral is already in the list, update its advertised data
            if let index = discoveredPeripherals.firstIndex(where: { $0.peripheral == peripheral }) {
                let module = discoveredPeripherals[index]
                module.connectionState = ConnectionState.not_connected
                module.scanningState = ScanningState.not_connected
                objectWillChange.send()
            }
        }
    }
    
    func disconnectFromDevice(module: DiscoveredPeripheral) {
        print("Disconnecting \(module.peripheral.name)")

        centralManager.cancelPeripheralConnection(module.peripheral)
    }

    func centralManager(_ central: CBCentralManager, didDisconnect peripheral: CBPeripheral) {
        print("Did disconnectconnect triggered, \(peripheral.name)")
        
        if !discoveredPeripheralSet.contains(peripheral) {
            // Add it to the list and the set
            print("Unexpected disconnection from \(peripheral)")
        } else {
            // If the peripheral is already in the list, update its advertised data
            if let index = discoveredPeripherals.firstIndex(where: { $0.peripheral == peripheral }) {
                let module = discoveredPeripherals[index]
                module.connectionState = ConnectionState.not_connected
                module.scanningState = ScanningState.not_connected
//                module.objectWillChange.send()
                objectWillChange.send()
                // Call module scan!
            }
        }

    }

    
}
