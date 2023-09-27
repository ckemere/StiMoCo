//
//  ModuleControl.swift
//  BLEScanner
//
//  Created by Caleb Kemere on 9/21/23.
//

/*
See the License.txt file for this sample’s licensing information.
*/

import SwiftUI




// IT WOULD BE COOL IF WE COULD SEND UPTIME AND BATTERY IN ADVERTISEMENTS!

struct ModuleControl: View {
    @ObservedObject var module: DiscoveredPeripheral
    @EnvironmentObject var bleManager: BluetoothManager
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var newStimParams:StimParameters = StimParameters()
        
    @State private var parametersChanged = false
    
    var body: some View {
        List {
            if (module.connectionState != ConnectionState.connected) {
                switch module.connectionState {
                case ConnectionState.not_connected:
                    Text("Not connected")
                case ConnectionState.disconnected:
                    Text("Not connected (disconnected)")
                case ConnectionState.waiting_for_connection:
                    Text("Waiting for connection")
                case ConnectionState.connected:
                    Text("Connected")
                }}
            else {
                switch module.scanningState {
                case ScanningState.not_connected:
                    Text("No scan (Not connected)")
                case ScanningState.retrieving_services:
                    Text("[Connected] Retrieving services")
                case ScanningState.querying_characteristics:
                    Text("[Connected] Querying characteristics")
                case ScanningState.retrieving_characteristics:
                    Text("[Connected] Retrieving characteristics")
                case ScanningState.module_updated:
                    Text("[Connected] Module data loaded")
                }
            }

            Button(action: {
                bleManager.connectToDevice(module: module)
            })
            {
                Text("Connect to Module")
            }
            Button(action: {
                //bleManager.disconnectDevice(module: module)
            })
            {
                Text("Reread Module Data")
            }
            Button(action: {
                //bleManager.disconnectDevice(module: module)
            })
            {
                Text("Disconnect Module")
            }
            
            VStack(alignment: .leading) {
                Text(module.peripheral.name ?? "Unknown Device")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Module Uptime: \(module.uptime)")
                
//                Text(module.advertisedData)
//                    .font(.caption)
//                    .foregroundColor(.gray)
                
                ModuleDetail(originalStimParams: $module.stimParameters,
                             newStimParams: $newStimParams,
                             parametersChanged: $parametersChanged)
                .onAppear {
                    newStimParams = module.stimParameters // Copy details in order to edit
                }
                
                HStack {
                    Button(action: {
                        module.stimParameters = newStimParams // Update module values
                        // THIS SHOULD CALL A BLE FUNCTION!
                        parametersChanged = false
                    }
                    ){
                        Text("Update Module")
                    }
                    .tint(.green)
                    .disabled(parametersChanged==false)
                    Button(action: {
                        newStimParams = module.stimParameters // Reset values
                        parametersChanged = false
                    }) {
                        Text("Cancel Changes")
                    }
                    .tint(.pink)
                    .disabled(parametersChanged==false)
                }
                .buttonStyle(.bordered)

//            }
//            .toolbar {
            }
        }
    }
}
//
//struct ModuleControl_Previews: PreviewProvider {
//    static var previews: some View {
//        ModuleControl(module: .constant(DiscoveredPeripheral()))
//    }
//}
