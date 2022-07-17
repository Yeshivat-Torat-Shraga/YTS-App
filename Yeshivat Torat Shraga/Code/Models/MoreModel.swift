//
//  SettingsModel.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 4/28/22.
//

import SwiftUI
import UserNotifications
import FirebaseMessaging

class MoreModel: ObservableObject {
    @Published var settingsToggleEnabled: Bool = false
    @Published var disabledReason: String? = nil
    @Published var showNotificationsAlert = false
    @Published var submitContentView: SubmitContentView
    @AppStorage("enableDevNotifications") var devNotificationsEnabled: Bool = false
    
    init(miniPlayerShowing: Binding<Bool>) {
        self.submitContentView = SubmitContentView(miniPlayerShowing: miniPlayerShowing)
        
        let currentNotifications = UNUserNotificationCenter.current()
        let acceptableNotificationStatuses: [UNAuthorizationStatus] = [.authorized, .ephemeral, .provisional]
        currentNotifications.getNotificationSettings { settings in
            if acceptableNotificationStatuses.contains(settings.authorizationStatus) {
                self.settingsToggleEnabled = true
            }
        }
    }
    
    func setSubscriptionToNotificationGroup(_ switchBinding: Binding<Bool>,group: String, shouldReceiveNotificationsFromGroup: Bool) {
        let currentNotifications = UNUserNotificationCenter.current()
        currentNotifications.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .denied:
                if shouldReceiveNotificationsFromGroup == false {
                    break
                }
                // Show alert saying we don't have permission to show notifications
                // Then set toggle to off
                DispatchQueue.main.async {
                    self.showNotificationsAlert = true
                    switchBinding.wrappedValue = false
                }
                break
            case .notDetermined:
                if shouldReceiveNotificationsFromGroup == false {
                    break;
                }
                let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
                UNUserNotificationCenter.current().requestAuthorization(
                    options: authOptions,
                    completionHandler: { granted, error in
                        if granted {
                            if shouldReceiveNotificationsFromGroup == true {
                                Messaging.messaging().subscribe(toTopic: group) { error in
                                    if let error = error {
                                        print("\n\n\nError subscribing to notifications: \(error)\n\n\n")
                                    }
                                }
                            } else {
                                Messaging.messaging().unsubscribe(fromTopic: group)
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.showNotificationsAlert = true
                                switchBinding.wrappedValue = false
                            }
                        }
                    }
                )
                
                break
            case .authorized,
                    .provisional,
                    .ephemeral:
                if shouldReceiveNotificationsFromGroup == true {
                    Messaging.messaging().subscribe(toTopic: group) { error in
                        if let error = error {
                            print("\n\n\nError subscribing to notifications: \(error)\n\n\n")
                        }
                        print("Subscribed to \(group) notifications successfuly")
                    }
                } else {
                    Messaging.messaging().unsubscribe(fromTopic: group)
                }
                // if the toggle is now set to ON, subscribe to notifications
                // if the toggle is now set to OFF, unsubscribe
                
                break
            @unknown default:
                break
            }
        }

    }
}
