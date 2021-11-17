//
//  FirebaseConnection.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 11/13/21.
//

import Foundation
import Firebase
import FirebaseFunctions

final class FirebaseConnection {
    static var functions = Functions.functions()
    
    /// Loads `Rabbi` objects from Firestore
    /// - Parameters:
    ///   - lastLoadedDocumentID: Pages results starting from first element afterwards
    ///   - count: The amount of `Rabbi` objects to return. Default is `10`
    ///   - includeProfilePictureURLs: Whether or not to include profile picture URLs in the response. Default is `true`
    ///   - completion: Callback which returns the results and metadata once function completes, including the new `lastLoadedDocumentID`
    static func loadRebbeim(lastLoadedDocumentID: FirestoreID? = nil, count requestedCount: Int = 10, includeProfilePictureURLs: Bool = true, completion: @escaping (_ results: (rabbis: [Rabbi], metadata: (newLastLoadedDocumentID: FirestoreID, includesLastElement: Bool))?, _ error: Error?) -> Void) {
        var rebbeim: [Rabbi] = []
        
        let data: NSDictionary
        if let lastLoadedDocumentID = lastLoadedDocumentID {
            data = NSDictionary(dictionary: ["lastLoadedDocumentID": lastLoadedDocumentID, "count": requestedCount, "includePictureURLs": includeProfilePictureURLs])
        } else {
            data = NSDictionary(dictionary: ["count": requestedCount])
        }
        
        let httpsCallable = functions.httpsCallable("loadRebbeim")
        
        httpsCallable.call(data) { callResult, callError in
            guard let response = callResult?.data as? [String: Any] else {
                completion(nil, callError ?? YTSError.noDataReceived)
                return
            }
            
            guard let rabbiDocuments = response["rabbis"] as? [[String: Any]] else {
                completion(nil, callError ?? YTSError.invalidDataReceived)
                return
            }
            
            guard let newLastLoadedDocumentID = response["lastLoadedDocumentID"] as? FirestoreID else {
                completion(nil, callError ?? YTSError.invalidDataReceived)
                return
            }
            
            guard let includesLastElement = response["includesLastElement"] as? Bool else {
                completion(nil, callError ?? YTSError.invalidDataReceived)
                return
            }
            
            let group = DispatchGroup()
            
            for _ in rabbiDocuments {
                group.enter()
            }
            
            for rabbiDocument in rabbiDocuments {
                guard let id = rabbiDocument["id"] as? FirestoreID, let name = rabbiDocument["name"] as? String else {
                    print("Document missing sufficient data. Continuing to next document.")
                    group.leave()
                    continue
                }
                
                if let profilePictureURLString = rabbiDocument["profile_picture_url"] as? String, let profilePictureURL = URL(string: profilePictureURLString) {
                    rebbeim.append(Rabbi(id: id, name: name, profileImageURL: profilePictureURL))
                    group.leave()
                    continue
                } else if let profilePictureFilename = rabbiDocument["profile_picture_filename"] as? String {
                    fatalError("This feature has not been implemented")
                } else {
                    print("Document missing sufficient data. Continuing to next document.")
                    group.leave()
                    continue
                }
            }
            
            group.notify(queue: .main) {
                completion((rabbis: rebbeim, metadata: (newLastLoadedDocumentID: newLastLoadedDocumentID, includesLastElement: includesLastElement)), callError)
            }
        }
    }
}
