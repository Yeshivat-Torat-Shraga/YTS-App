//
//  SettingsView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 06/12/2021.
//

import SwiftUI
import FirebaseMessaging
import FirebaseAnalytics

struct SettingsView: View {
    @ObservedObject var model = SettingsModel()
    @EnvironmentObject var favorites: Favorites
    @State var showClearFavoritesConfirmation = false
    @State var showNotificationsAlert = false
    @AppStorage("slideshowAutoScroll") private var enableTimer = true
    
    var miniPlayerShowing: Binding<Bool>
    
    init(miniPlayerShowing: Binding<Bool>) {
        self.miniPlayerShowing = miniPlayerShowing
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Toggle("Enable Notifications", isOn: $model.settingsToggleEnabled)
                        .onChange(of: model.settingsToggleEnabled) { newToggleValue in
                            let currentNotifications = UNUserNotificationCenter.current()
                            currentNotifications.getNotificationSettings { settings in
                                switch settings.authorizationStatus {
                                case .denied:
                                    if newToggleValue == false {
                                        break;
                                    }
                                    // Show alert saying we don't have permission to show notifications
                                    // Then set toggle to off
                                    showNotificationsAlert = true
                                    model.toggleSettings(newValue: false)
                                    break
                                case .notDetermined:
                                    if newToggleValue == false {
                                        break;
                                    }
                                    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
                                    UNUserNotificationCenter.current().requestAuthorization(
                                        options: authOptions,
                                        completionHandler: { granted, error in
                                            if granted {
                                                if newToggleValue == true {
                                                    Messaging.messaging().subscribe(toTopic: "all") { error in
                                                        if let error = error {
                                                            print("\n\n\nError subscribing to notifications: \(error)\n\n\n")
                                                        }
                                                    }
                                                } else {
                                                    Messaging.messaging().unsubscribe(fromTopic: "all")
                                                }
                                            } else {
                                                showNotificationsAlert = true
                                                model.toggleSettings(newValue: false)
                                            }
                                        }
                                    )
                                    
                                    break
                                case .authorized,
                                        .provisional,
                                        .ephemeral:
                                    if newToggleValue == true {
                                        Messaging.messaging().subscribe(toTopic: "all") { error in
                                            if let error = error {
                                                print("\n\n\nError subscribing to notifications: \(error)\n\n\n")
                                            }
                                            print("Subscribed to all notifications successfuly")
                                        }
                                    } else {
                                        Messaging.messaging().unsubscribe(fromTopic: "all")
                                    }
                                    // if the toggle is now set to ON, subscribe to notifications
                                    // if the toggle is now set to OFF, unsubscribe
                                    
                                    break
                                @unknown default:
                                    break
                                }
                            }
                        }
                        .foregroundColor(Color("ShragaBlue"))
                    
                    Toggle("Slideshow Autoscroll", isOn: $enableTimer)
                        .foregroundColor(Color("ShragaBlue"))
                }
                
                Section {
                    NavigationLink("About") {
                        AboutView(miniPlayerShowing: miniPlayerShowing)
                    }.foregroundColor(Color("ShragaBlue"))
                }
                
                Section {
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
            }
            .navigationTitle("Settings")
            .listStyle(InsetGroupedListStyle())
            
//            if audioPlayerModel.audio != nil {
//                Spacer().frame(height: UI.playerBarHeight)
//            }
        }
        .alert(isPresented: $showNotificationsAlert) {
            Alert(title: Text("Uh oh"), message: Text("You'll need to enable notification permission for this app first."),
                  primaryButton: .default(Text("Open Settings")) {
                if let appSettings = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(appSettings) {
                    UIApplication.shared.open(appSettings)
                }
            }, secondaryButton: .cancel())
        }
        .foregroundColor(.blue)
        .onAppear {
            Analytics.logEvent("opened_view", parameters: [
                "page_name": "Settings"
            ])
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(miniPlayerShowing: .constant(false))
            .environmentObject(Favorites())
    }
}
