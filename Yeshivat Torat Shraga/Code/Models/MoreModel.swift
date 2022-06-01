//
//  SettingsModel.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 4/28/22.
//

import Foundation
import UserNotifications
import SwiftUI

class MoreModel: ObservableObject {
    @Published var settingsToggleEnabled: Bool = false
    @Published var disabledReason: String? = nil
    
    @Published var submitContentView: SubmitContentView
    
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
    
    func toggleSettings(newValue: Bool) {
        settingsToggleEnabled = newValue
    }
}
