//
//  FirebaseConnection.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 11/13/21.
//

import Foundation
import Firebase

final class FirebaseConnection {
    static var functions = Functions.functions()
    
    /// Loads `Rabbi` objects from Firestore
    /// - Parameters:
    ///   - lastLoadedDocumentID: Pages results starting from first element afterwards
    ///   - requestedCount: The amount of `Rabbi` objects to return. Default is `10`
    ///   - completion: Callback which returns the results and metadata once function completes, including the new `lastLoadedDocumentID`
    static func loadRabbis(lastLoadedDocumentID: FirestoreID? = nil, requestedCount: Int = 10, completion: (_ results: (rabbis: [Rabbi], metadata: (newLastLoadedDocumentID: FirestoreID, includesLastElement: Bool))?, _ error: Error?) -> Void) {
        
        let data = NSDictionary(dictionary: ["count": requestedCount])
        
        let httpsCallable = functions.httpsCallable("loadRabbis")
        
        httpsCallable.call(data) { callResult, callError in
        }
    }
}
