//
//  StimParamWidget.swift
//  BLEScanner
//
//  Created by Caleb Kemere on 9/27/23.
//

/*
 See the License.txt file for this sample’s licensing information.
 */


import SwiftUI

//let stimFrequencies:[UInt16] = [40, 120, 130]
//let stimCurrents:[UInt8] = [40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150]


struct StimParamWidget: View {
    var description: String = ""
    @Binding var originalValue: Int
    @State var is_editing = false
    
    var units = "Hz"
    @State var newValue: Int = 0
    
    func frequencyFromPeriod (period: UInt32) -> Int {
        return Int(32768.0/Float(period))
    }
    
    //    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        HStack(spacing: 5) {
            Text(description)
                .frame(width: 100)
            
            if (!is_editing) {
                Text("\(originalValue) \(units)")
                    .textFieldStyle(.roundedBorder)
                    .frame(width:100)
                
                Button (action: {is_editing = true}) {
                    Label("Change", systemImage: "gearshape")
                }
                .labelStyle(.iconOnly)
                .frame(width: 40)
                
            }
            else {
                Picker("Value", selection: $newValue) {
                    ForEach(1 ..< 200) { number in
                        Text("\(number) \(units)")
                    }
                }
                .onAppear{newValue = originalValue}
                .pickerStyle(.wheel)
                .labelsHidden()
                .frame(width:120)
                .compositingGroup()
                .clipped()
                
                Button (action: {is_editing = false}) {
                    Label("Update", systemImage: "checkmark.square")
                }
                .labelStyle(.iconOnly)
                .frame(width:40)
                
                Button (action: {is_editing = false}) {
                    Label("Cancel", systemImage: "x.square")
                }
                .labelStyle(.iconOnly)
                .frame(width:40)
            }
        }
        .font(.headline)
        .frame(alignment: .leading)
    }
}
//
//struct ModuleControl_Previews: PreviewProvider {
//    static var previews: some View {
//        ModuleControl(module: .constant(DiscoveredPeripheral()))
//    }
//}
