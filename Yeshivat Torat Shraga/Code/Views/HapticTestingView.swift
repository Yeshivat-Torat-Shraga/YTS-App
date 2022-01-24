//
//  HapticTestingView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 24/01/2022.
//

import SwiftUI

struct HapticTestingView: View {
    let types = [
        "Heavy", "Medium",
        "Light", "Rigid",
        "Soft", "Success",
        "Warning", "Error",
        "Impact"
    ]
    
    let actions: [() -> ()] = [
        {Haptics.shared.play(.heavy)},
        {Haptics.shared.play(.medium)},
        {Haptics.shared.play(.light)},
        {Haptics.shared.play(.rigid)},
        {Haptics.shared.play(.soft)},
        {Haptics.shared.notify(.success)},
        {Haptics.shared.notify(.warning)},
        {Haptics.shared.notify(.error)},
        {Haptics.shared.impact()},
    ]
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(types.indices) { i in
                        Button(action: {actions[i]}()) {
                            Text(types[i])
                                .foregroundColor(.black)
                                .bold()
                                .padding()
                                .frame(width: 100)
                                .background(Color.blue)
                                .cornerRadius(7)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Haptics")
        }
    }
}

struct HapticTestingView_Previews: PreviewProvider {
    static var previews: some View {
        HapticTestingView()
    }
}
