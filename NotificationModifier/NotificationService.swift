//
//  NotificationService.swift
//  NotificationModifier
//
//  Created by Benji Tusk on 7/13/22.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    let defaults = UserDefaults(suiteName: "group.com.reesedevelopment.YTS")

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        var count = defaults?.value(forKey: "count") as! Int
        
        if let bestAttemptContent = bestAttemptContent {
            // Modify the notification content here...
            if let badgeCount = bestAttemptContent.badge {
                // badgeCount is the number sent by the notification
                // bestAttemptContent.badge will be the number shown to the user
                // count is the stored number of notifications
                count += Int(truncating: badgeCount)
                bestAttemptContent.badge = (count) as NSNumber
                defaults?.set(count, forKey: "count")
            }
            contentHandler(bestAttemptContent)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
