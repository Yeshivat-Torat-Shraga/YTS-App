//
//  SettingsView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 06/12/2021.
//

import SwiftUI

struct SettingsView: View {
    @State private var enableNotifications = false
    @State var showClearFavoritesConfirmation = false
    
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Toggle("Enable Notifications", isOn: $enableNotifications)
                }
                
                Section {
                    Button {
                        showClearFavoritesConfirmation = true
                    } label: {
                        Text("Clear favorites")
                    }.alert(isPresented: self.$showClearFavoritesConfirmation, content: {
                        Alert(title: Text("Confirmation"), message: Text("Are you sure you want to clear all favorites? This action cannot be undone."), primaryButton: Alert.Button.cancel(), secondaryButton: Alert.Button.destructive(Text("Delete"), action: {
                            Favorites.clearFavorites()
                        }))
                    })
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
