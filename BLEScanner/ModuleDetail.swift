//
//  ModuleEditor.swift
//  BLEScanner
//
//  Created by Caleb Kemere on 9/23/23.
//

/*
See the License.txt file for this sample’s licensing information.
*/


import SwiftUI

let stimFrequencies:[UInt16] = [40, 120, 130]
let stimCurrents:[UInt8] = [40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150]


struct ModuleDetail: View {
    @Binding var originalStimParams: StimParameters
    @Binding var newStimParams: StimParameters
    @Binding var parametersChanged: Bool

//    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading) {
            Picker("Stim Frequency", selection: $newStimParams.period) {
                ForEach(stimFrequencies, id: \.self) {sf in
                    Text(String("\(sf) Hz"))
                }
            }
            .onChange(of: newStimParams.period, perform: {_ in
                if (newStimParams.period != originalStimParams.period) {
                    parametersChanged = true
                }
            })
            Picker("Stim Current", selection: $newStimParams.current) {
                ForEach(stimCurrents, id: \.self) {sc in
                    Text(String("\(sc) µA"))
                }
            }
            .onChange(of: newStimParams.current, perform: {_ in
                if (newStimParams.current != originalStimParams.current) {
                    parametersChanged = true
                }
            })

        }
    }
}
//
//struct ModuleControl_Previews: PreviewProvider {
//    static var previews: some View {
//        ModuleControl(module: .constant(DiscoveredPeripheral()))
//    }
//}
