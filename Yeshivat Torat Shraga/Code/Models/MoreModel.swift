//
//  SettingsModel.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 4/28/22.
//

import Foundation
import UserNotifications

class MoreModel: ObservableObject {
    @Published var settingsToggleEnabled: Bool = false
    @Published var disabledReason: String? = nil
    init() {
        let currentNotifications = UNUserNotificationCenter.current()
        let acceptableNotificationStatuses: [UNAuthorizationStatus] = [.authorized, .ephemeral, .provisional]
        currentNotifications.getNotificationSettings { settings in
            if acceptableNotificationStatuses.contains(settings.authorizationStatus) {
                self.settingsToggleEnabled = true
            }
        }
    }
    
    func toggleSettings(newValue: Bool) {
        settingsToggleEnabled = newValue
    }
}
