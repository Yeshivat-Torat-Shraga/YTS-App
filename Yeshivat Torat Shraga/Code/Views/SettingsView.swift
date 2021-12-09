//
//  SettingsView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 06/12/2021.
//

import SwiftUI

struct SettingsView: View {
    @State private var toggle = false
    var body: some View {
        NavigationView {
            List {
                HStack {
                    Toggle("Enable Notifications", isOn: $toggle)
                }
            }
            .navigationTitle("Settings")
            .listStyle(InsetGroupedListStyle())
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
