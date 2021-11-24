//
//  Helpers.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 11/24/21.
//

import Foundation

func timeFormatted(totalSeconds: TimeInterval) -> String {
    let seconds: Int = Int((totalSeconds).truncatingRemainder(dividingBy: 60))
    let minutes: Int = Int(((totalSeconds / 60.0).truncatingRemainder(dividingBy: 60)))
    let hours: Int = Int(((totalSeconds / 3600).truncatingRemainder(dividingBy: 60)))
    if hours > 0 {
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    } else {
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

func timeFormattedMini(totalSeconds: TimeInterval) -> String {
    let seconds: Int = Int((totalSeconds).truncatingRemainder(dividingBy: 60))
    let minutes: Int = Int(((totalSeconds / 60.0).truncatingRemainder(dividingBy: 60)))
    let hours: Int = Int(((totalSeconds / 3600.0).truncatingRemainder(dividingBy: 60)))
    if hours > 0 {
        var str = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        if str.first == "0" {
            str.removeFirst()
        }
        return str
    } else {
        var str = String(format: "%02d:%02d", minutes, seconds)
        if str.first == "0" {
            str.removeFirst()
        }
        return str
    }
}
