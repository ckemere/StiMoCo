//
//  DeviceList.swift
//
//  From BLESCanner, Created by Christian Möller on 02.01.23.
//

import SwiftUI
import CoreBluetooth


struct ModuleRow: View {
    let module: DiscoveredPeripheral
    
    var body: some View {
        HStack {
//            Image(uiImage: UIImage(named: "AppIcon") ?? UIImage())
            Text(module.peripheral.name ?? "Unknown Device")
                .fontWeight(.bold)
        }
    }
}


struct DeviceList: View {
    @ObservedObject private var bluetoothScanner = BluetoothScanner()
//    @State private var searchText = ""

    var body: some View {
        VStack {
            NavigationView {
                // List of discovered peripherals
//                List {
//                    ForEach(bluetoothScanner.discoveredPeripherals,
//                            id: \.peripheral.identifier) { module in
//                        NavigationLink {
//                            ModuleControl(module: module)
//                        } label: {
//                            ModuleRow(module: module)
//                        }
//                    }
//                }
                
//                List(bluetoothScanner.discoveredPeripherals,
//                     id: \.peripheral.identifier) { module in
//                    NavigationLink {
//                        ModuleControl(module: module)
//                    } label: {
//                        ModuleRow(module: module)
//                    }
//
//                }
                List($bluetoothScanner.discoveredPeripherals,
                     id: \.peripheral.identifier) { $module in
                    NavigationLink{
                        ModuleControl(module:$module)
                    } label: {
                        ModuleRow(module:module)
                    }
                }
                .navigationTitle("Discovered Modules")
                
//                List(bluetoothScanner.discoveredPeripherals,
//                     id: \.peripheral.identifier) { discoveredPeripheral in
//                    VStack(alignment: .leading) {
//                        Text(discoveredPeripheral.peripheral.name ?? "Unknown Device")
//                        Text(discoveredPeripheral.advertisedData)
//                            .font(.caption)
//                            .foregroundColor(.gray)
//                    }
//                }
//                     .navigationTitle("Discovered Modules")
            }
            // Button for starting or stopping scanning
            Button(action: {
                if self.bluetoothScanner.isScanning {
                    self.bluetoothScanner.stopScan()
                } else {
                    self.bluetoothScanner.startScan()
                }
            }) {
                if bluetoothScanner.isScanning {
                    Text("Stop Scanning")
                } else {
                    Text("Scan for Devices")
                }
            }
            // Button looks cooler this way on iOS
            .padding()
            .background(bluetoothScanner.isScanning ? Color.red : Color.blue)
            .foregroundColor(Color.white)
            .cornerRadius(5.0)

        }
    }
}
