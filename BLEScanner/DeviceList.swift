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
    @StateObject private var bleManager = BluetoothManager()
//    @ObservedObject private var bleManager = BluetoothScanner()
//    @State private var searchText = ""

    var body: some View {
        VStack {
            NavigationView {
                // List of discovered peripherals
                List(bleManager.discoveredPeripherals,
                     id: \.peripheral.identifier) { module in
                    NavigationLink{
                        ModuleControl(module:module)
                            .border(Color.gray)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .onAppear(){
                                bleManager.connectToDevice(module: module)
                            }
                            .onDisappear(){
                                bleManager.disconnectFromDevice(module: module)
                                module.connectionState = ConnectionState.not_connected
                                module.scanningState = ScanningState.not_connected
                            }
                    } label: {
                        ModuleRow(module:module)
                    }
                }
                .navigationTitle("Discovered Modules")
            }
            .environmentObject(bleManager)

            // Button for starting or stopping scanning
            Button(action: {
                if self.bleManager.isScanning {
                    self.bleManager.stopScan()
                } else {
                    self.bleManager.startScan()
                }
            }) {
                if bleManager.isScanning {
                    Text("Stop Scanning")
                } else {
                    Text("Scan for Devices")
                }
            }
            // Button looks cooler this way on iOS
            .padding()
            .background(bleManager.isScanning ? Color.red : Color.blue)
            .foregroundColor(Color.white)
            .cornerRadius(5.0)

        }
    }
}
