//
//  FirebaseConnection.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 11/13/21.
//

import Foundation

final class FirebaseConnection {
    static func loadRabbis(lastLoadedDocumentID: FirestoreID? = nil, requestedCount: Int = 10, completion: (_ results: (rabbis: [Rabbi], metadata: (newLastLoadedDocumentID: FirestoreID, includesLastElement: Bool))?, _ error: Error?) -> Void) {
        
    }
}
