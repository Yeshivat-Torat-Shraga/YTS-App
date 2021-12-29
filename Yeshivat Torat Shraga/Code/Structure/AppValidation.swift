//
//  AppValidation.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 12/29/21.
//

import Foundation

import Foundation
import Firebase
import FirebaseAppCheck

class KHKAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
  func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
    return AppAttestProvider(app: app)
  }
}
