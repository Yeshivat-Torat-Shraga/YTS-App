//
//  SettingsView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 06/12/2021.
//

import SwiftUI
import FirebaseMessaging
import FirebaseAnalytics

struct MoreView: View {
    @ObservedObject var model: MoreModel
    @EnvironmentObject var favorites: Favorites
    @State var showClearFavoritesConfirmation = false
    @AppStorage("slideshowAutoScroll") private var enableTimer = true
    @AppStorage("showDeveloperSettings") private var showDevSettings = false
    
    var miniPlayerShowing: Binding<Bool>
    
    init(miniPlayerShowing: Binding<Bool>) {
        self.miniPlayerShowing = miniPlayerShowing
        self.model = MoreModel(miniPlayerShowing: miniPlayerShowing)
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Toggle("Enable Notifications", isOn: $model.settingsToggleEnabled)
                        .onChange(of: model.settingsToggleEnabled) { newToggleValue in
                            model.setSubscriptionToNotificationGroup($model.settingsToggleEnabled, group: "all", shouldReceiveNotificationsFromGroup: newToggleValue)
                        }
                        .foregroundColor(Color("ShragaBlue"))
                    
                    Toggle("Slideshow Autoscroll", isOn: $enableTimer)
                        .foregroundColor(Color("ShragaBlue"))
                    
                    Button {
                        showClearFavoritesConfirmation = true
                    } label: {
                        Text("Clear favorites")
                    }
                    .foregroundColor(.red)
                    .alert(isPresented: self.$showClearFavoritesConfirmation, content: {
                        Alert(title: Text("Confirmation"), message: Text("Are you sure you want to clear all favorites? This action cannot be undone."), primaryButton: Alert.Button.cancel(), secondaryButton: Alert.Button.destructive(Text("Delete"), action: {
                            favorites.clearFavorites()
                        }))
                    })
                }
                
                if #available(iOS 15, *) {
                    Section(header: Text("Contribute")) {
                        NavigationLink("Submit Content", destination: model.submitContentView)
                    }
                } else {
                    Section(header: Text("Contribute"), footer: Text("Upgrade to iOS 15 or above to use this feature.")) {
                        NavigationLink("Submit Content", destination: model.submitContentView)
                            .disabled(true)
                    }
                }
                
                Section {
                    NavigationLink("About") {
                        AboutView(miniPlayerShowing: miniPlayerShowing)
                    }.foregroundColor(Color("ShragaBlue"))
                } header: {
                    Text("YTS")
                }
                
                if showDevSettings {
                    Section(header: Text("Developer")) {
                    Toggle("Developer Notifications", isOn: $model.devNotificationsEnabled)
                        .onChange(of: model.devNotificationsEnabled) { newToggleValue in
                            model.setSubscriptionToNotificationGroup($model.devNotificationsEnabled, group: "debug", shouldReceiveNotificationsFromGroup: newToggleValue)
                        }
                    
                    NavigationLink("Pending Shiurim") {
                        model.pendingShiurimView
                    }
                    }
                }
            }
            .navigationTitle("More")
            .navigationBarItems(trailing: LogoView(size: .small))
            .listStyle(InsetGroupedListStyle())
            
            if miniPlayerShowing.wrappedValue {
                Spacer().frame(height: UI.playerBarHeight)
            }
        }
        .alert(isPresented: $model.showNotificationsAlert) {
            Alert(title: Text("Uh oh"), message: Text("You'll need to enable notification permissions for this app first."),
                  primaryButton: .default(Text("Open Settings")) {
                if let appSettings = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(appSettings) {
                    UIApplication.shared.open(appSettings)
                }
            }, secondaryButton: .cancel())
        }
        //        .foregroundColor(.blue)
        .onAppear {
            Analytics.logEvent("opened_view", parameters: [
                "page_name": "Settings"
            ])
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        MoreView(miniPlayerShowing: .constant(false))
            .environmentObject(Favorites())
    }
}
