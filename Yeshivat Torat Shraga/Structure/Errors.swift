//
//  Errors.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 11/10/21.
//

import Foundation

enum YTSError {
    
}

/// Prepares a model class to show errors in its parent view
/// - Note: This protocol was taken from the KHK app code
protocol ErrorShower: ObservableObject {
    typealias Closure = () -> Void
    
    /// Errror to display message from in the UI
    /// - Note: Reccomended defualt value is `nil` and recommended access modifier is `internal`
    var errorToShow: Error? { get set }
    
    associatedtype ErrorClosure = Closure
    
    
    /// Closure to call on retry attempt from the UI
    /// - Note: Reccomended defualt value is `nil` and recommended access modifier is `internal`
    var retry: ErrorClosure? { get set }
    
    
    /// Whether or not an error should be shown/is being shown
    /// - Note: Reccomended defualt value is `false` and recommended access modifier is `public` with an `@Published` attribute
    var showError: Bool { get set }
}

extension ErrorShower {
    /// Called to show an error on the UI
    /// - Parameters:
    ///   - error: `Error` to present
    ///   - retry: `ErrorClosure` to call when the uses elects to retry the failed process
    /// - Note: Recommended access modifier is `public`
    func showError(error: Error, retry: ErrorClosure) {
        self.errorToShow = error
        self.retry = retry
        self.showError = true
    }
}
