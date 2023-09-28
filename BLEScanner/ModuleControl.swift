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
    
    @State private var is_editing = false
    
    func TimeString(seconds: UInt32) -> String
    {
        var hours = seconds / 3600
        var minutes = (seconds - hours*3600)/60
        var residual = seconds - hours*3600 - minutes*60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, residual)
    }
    
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

            HStack{
                Button(action: {
                    bleManager.connectToDevice(module: module)
                })
                {
                    Text("Connect to Module")
                }
                Button(action: {
                    module.requery_module()
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
            }
            
            VStack(alignment: .leading) {
                Text(module.peripheral.name ?? "Unknown Device")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Module Uptime: \(TimeString(seconds:module.uptime))")
                
//                Text(module.advertisedData)
//                    .font(.caption)
//                    .foregroundColor(.gray)
                    
                if (is_editing) {
                    ModuleDetail(stimParams: $newStimParams, updateFreshness: $module.updateFreshness)
                    .onAppear {
                        newStimParams = module.stimParameters // Copy details in order to edit
                    }
                }
                else {
                    ModuleDetail(stimParams: $module.stimParameters, updateFreshness: $module.updateFreshness, is_active: false)
                }
                                    
                HStack {
                    Button(action: {
                        if (!is_editing) {
                            is_editing = true
                        }
                        else
                        {
                            newStimParams = module.stimParameters // Reset values
                            is_editing = false
                        }
                    }){
                        if (!is_editing) {
                            Label("Lock", systemImage: "lock").labelStyle(.iconOnly).font(.title)

                        }
                        else {
                            Label("Unlock", systemImage: "lock.open").labelStyle(.iconOnly).font(.title)
                        }
                    }
                    .background(Color.white)
                    .foregroundColor(Color.gray)
                    .clipShape(RoundedRectangle(cornerRadius: 10))


                    Button(action: {
                        if (module.stimParameters.frequency != newStimParams.frequency) {
                            module.updateFrequency(new_frequency: newStimParams.frequency)
                        }
                        else if (module.stimParameters.current != newStimParams.current) {
                            module.updateCurrent(new_current: newStimParams.current)
                        }
                        module.stimParameters = newStimParams // Update module values
                    }
                    ){
                        Label("Update", systemImage: "arrow.up").labelStyle(.iconOnly).font(.title)
                    }
                    .accentColor(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .disabled(!is_editing || (module.stimParameters == newStimParams))

                    Button(action: {
                        newStimParams = module.stimParameters // Reset values
                    }) {
                        Label("Undo", systemImage: "arrow.uturn.backward").labelStyle(.iconOnly).font(.title)
                    }
                    .accentColor(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .disabled(!is_editing || (module.stimParameters == newStimParams))
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
