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

struct ModuleControl: View {
    @Binding var module: DiscoveredPeripheral
    
//    @EnvironmentObject var eventData: EventData
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text(module.peripheral.name ?? "Unknown Device")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(module.advertisedData)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .toolbar {
            }
            .onAppear {
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
