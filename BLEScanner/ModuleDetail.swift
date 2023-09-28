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

let stimFrequencies = [Int](0...200)
let stimCurrents = [UInt8](0...200)

struct ModuleDetail: View {
    @Binding var stimParams: StimParameters
    @Binding var updateFreshness: UpdateFreshness
    @State var is_active = true
//    @Binding var parametersChanged: Bool
    //    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            HStack {
                if (!updateFreshness.period) {
                    Text(Image(systemName:"timelapse")) + Text("Stim Frequency")
                        .font(.title2)
                        .foregroundColor(Color.gray)
                }
                else {
                    Text("Stim Frequency")
                        .font(.title2)
                }
                
                Picker("Stim Frequency", selection: $stimParams.frequency)
                {
                    ForEach(stimFrequencies, id:\.self) {
                        Text("\($0) Hz")
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 150, height: 100)
                .clipped()
                .allowsHitTesting(is_active)
            }
            HStack {
                if (!updateFreshness.current) {
                    Text(Image(systemName:"timelapse")) + Text("Stim Current")
                        .font(.title2)
                        .foregroundColor(Color.gray)
                }
                else {
                    Text("Stim Current")
                        .font(.title2)
                }

                Picker("Stim Current", selection: $stimParams.current)
                {
                    ForEach(stimCurrents, id:\.self) {
                        Text("\($0) µA")
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 150, height: 100)
                .clipped()
                .allowsHitTesting(is_active)
            }
//            .onChange(of: newStimParams.current, perform: {_ in
//                if (newStimParams.current != originalStimParams.current) {
//                    parametersChanged = true
//                }
//            })
        }
    }
}
//
//struct ModuleControl_Previews: PreviewProvider {
//    static var previews: some View {
//        ModuleControl(module: .constant(DiscoveredPeripheral()))
//    }
//}
