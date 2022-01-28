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

// https://stackoverflow.com/a/58913649
extension String {
    func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }
    
    func substring(to: Int) -> String {
        let toIndex = index(from: to)
        return String(self[..<toIndex])
    }
}

extension Date {
    func get(_ components: Calendar.Component..., calendar: Calendar = Calendar.current) -> DateComponents {
        return calendar.dateComponents(Set(components), from: self)
    }
    
    func get(_ component: Calendar.Component, calendar: Calendar = Calendar.current) -> Int {
        return calendar.component(component, from: self)
    }
    
    static func monthNameFor(_ number: Int, short: Bool = false) -> String? {
        let monthName: String
        switch number {
        case 1:
            monthName = "January"
        case 2:
            monthName = "Feburary"
        case 3:
            monthName = "March"
        case 4:
            monthName = "April"
        case 5:
            monthName = "May"
        case 6:
            monthName = "June"
        case 7:
            monthName = "July"
        case 8:
            monthName = "August"
        case 9:
            monthName = "September"
        case 10:
            monthName = "October"
        case 11:
            monthName = "November"
        case 12:
            monthName = "December"
        default:
            return nil
        }
        return short ? monthName.substring(to: 3) : monthName
    }
}

extension Error {
    func getUIDescription() -> String {
        let code: Int
        if self is YTSError {
            code = (self as! YTSError).customCode
        } else {
            code = self._code
        }
        switch code {
        case NSURLErrorNotConnectedToInternet:
            return "Sorry, it seems you don't have an internet connection."
        default:
            return "An unknown error has occured. (\(code))"
        }
    }
}


/// This protocol is sourced from the Kol Hatorah Kulah App repository.
/// - https://github.com/davidreese/Kol-Hatorah-Kulah-SwiftUI
protocol SequentialLoader: ObservableObject {
    /// Whether or not the class is loading content from Firebase.
    ///
    /// Default: `false`
    ///
    /// Recommended access modifier: `internal`
    ///
    /// Recommended @attribute: `@Published`
    var loadingContent: Bool { get set }
    
    /// Whether or not the class is reloading all the data from Firebase that it's responsible for.
    ///
    /// Default: `false`
    ///
    /// Recommended access modifier: `internal`
    ///
    /// Recommended @attribute: none
    var reloadingContent: Bool { get set }
    
    /// Whether or not the class has attempted to get all Firebase data.
    ///
    /// Default: `false`
    ///
    /// Recommended access modifier: `internal`
    ///
    /// Recommended @attribute: `@Published`
    var retreivedAllContent: Bool { get set }
    
    /*
     /// Description: indexes of content, ordered in Firebase, that have been attempted to load.
     ///
     /// Default: `[]`
     ///
     /// Recommended access modifier: `private`
     ///
     /// Recommended @attribute: none
     var contentIndexesLoaded: [Int] { get set }
     */
    
    /// `firestoreID` of last content entity, ordered in Firebase, that was received.
    ///
    /// Default: `nil`
    ///
    /// Recommended access modifier: `internal`
    ///
    /// Recommended @attribute: none
    var lastLoadedDocumentID: FirestoreID? { get set }
    
    /// Determines whether or not the ``initialLoad`` function was ever called.
    ///
    /// Default: `false`
    ///
    /// Recommended access modifier: `internal`
    ///
    /// Recommended @attribute: none
    var calledInitialLoad: Bool { get set }
    
    //    func load(range: ClosedRange<Int>)
    
    func load(next increment: Int)
    
    func initialLoad()
    
    func reload()
}
