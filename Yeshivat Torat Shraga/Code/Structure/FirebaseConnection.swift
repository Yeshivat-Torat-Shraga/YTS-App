//
//  FirebaseConnection.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 11/13/21.
//

import Foundation
import Firebase
import FirebaseFunctions
import SwiftUI

final class FirebaseConnection {
    static var functions = Functions.functions()
    
    typealias ContentOptions = (limit: Int, includeThumbnailURLs: Bool, includeDetailedAuthors: Bool, startAfterDocumentID: FirestoreID?)
    typealias RebbeimOptions = (limit: Int, includePictureURLs: Bool, startAfterDocumentID: FirestoreID?)
    
    typealias Metadata = (newLastLoadedDocumentID: FirestoreID?, finalCall: Bool)
    
    static func loadAlert(completion: @escaping (_ result: HomePageAlert?, _ error: Error?) -> Void) {
        functions.httpsCallable("loadAlert").call() { callResult, callError in
            guard let response = callResult?.data as? [String: Any] else {
                completion(nil, callError ?? YTSError.noDataReceived)
                return
            }
            
            // Check if response contains valid data
            guard let alerts = response["results"] as? [[String: Any]] else {
                completion(nil, callError ?? YTSError.invalidDataReceived)
                return
            }
            
            guard alerts.count == 1 else {
                completion(nil, callError ?? YTSError.noDataReceived)
                return
            }
            
            let alert = alerts[0]
            
            guard let title = alert["title"] as? String,
                  let body = alert["body"] as? String,
                  let id = alert["id"] as? String
            else {
                completion(nil, callError ?? YTSError.invalidDataReceived)
                return
            }
            completion(HomePageAlert(id: id, title: title, body: body), nil)
        }
    }
    
    static func loadNews(lastLoadedDocumentID: FirestoreID? = nil, limit: Int = 15, completion: @escaping (_ results: (articles: [NewsArticle], metadata: Metadata)?, _ error: Error?) -> Void) {
        var articles: [NewsArticle] = []
        let httpsCallable = functions.httpsCallable("loadNews")
        
        var data: [String: Any] = [
            "limit": limit
        ]
        if let lastLoadedDocumentID = lastLoadedDocumentID {
            data["lastLoadedDocID"] = lastLoadedDocumentID
        }
        
        httpsCallable.call(data) { callResult, callError in
            // Check if there was any data received
            guard let response = callResult?.data as? [String: Any] else {
                completion(nil, callError ?? YTSError.noDataReceived)
                return
            }
            
            // Check if response contains valid data
            guard let urlDocuments = response["results"] as? [[String: Any]] else {
                completion(nil, callError ?? YTSError.invalidDataReceived)
                return
            }
            let finalCall = response["finalCall"] as? Bool ?? true
            var newLastLoadedDocumentID = response["lastLoadedDocID"] as? FirestoreID
            
            if newLastLoadedDocumentID == nil && lastLoadedDocumentID != nil {
                print("This isn't supposed to happen, the sequential loader will run in circles...")
                newLastLoadedDocumentID = lastLoadedDocumentID
            }
            
            let group = DispatchGroup()
            for _ in urlDocuments {
                group.enter()
            }
            
            for document in urlDocuments {
                guard let body = document["body"] as? String, let title = document["title"] as? String, let author = document["author"] as? String, let uploadDict = document["uploaded"] as? [String: Int] else {
                    print("Invalid data. Exiting scope.")
                    group.leave()
                    return
                }
                
                guard let uploaded = Date(firebaseTimestampDictionary: uploadDict) else {
                    print("Invalid date value. Exiting scope.")
                    group.leave()
                    continue
                }
                
                var slideshow: [SlideshowImage] = []
                
                if let urls = document["imageURLs"] as? [String] {
                    for url in urls {
                        let urlObject = URL(string: url)!
                        let image = SlideshowImage(url: urlObject, name: nil, uploaded: Date.init(timeIntervalSince1970: 0))
                        slideshow.append(image)
//                        slideshow.append(SlideshowImage(image: Image("SampleRabbi")))
                    }
                }
                
                let article = NewsArticle(title: title, body: body, uploaded: uploaded, author: author, images: slideshow)
                articles.append(article)
                group.leave()
            }
            group.notify(queue: .main) {
                completion((articles: articles, metadata: (newLastLoadedDocumentID: newLastLoadedDocumentID, finalCall: finalCall)), callError)
            }
        }
    }
    
    static func loadSlideshowImages(lastLoadedDocumentID: FirestoreID? = nil, limit: Int, completion: @escaping (_ results: (images: [SlideshowImage], metadata: Metadata)?, _ error: Error?) -> Void) {
        var images: [SlideshowImage] = []
        
        let httpsCallable = functions.httpsCallable("loadSlideshow")
        
        var data: [String: Any] = [
            "limit": limit
        ]
        if let lastLoadedDocumentID = lastLoadedDocumentID {
            data["lastLoadedDocID"] = lastLoadedDocumentID
        }
        
        httpsCallable.call(data) { callResult, callError in
            // Check if there was any data received
            guard let response = callResult?.data as? [String: Any] else {
                completion(nil, callError ?? YTSError.noDataReceived)
                return
            }
            
            // Check if response contains valid data
            guard let imageDocuments = response["results"] as? [[String: Any]],
                  let metadata = response["metadata"] as? [String: Any] else {
                completion(nil, callError ?? YTSError.invalidDataReceived)
                return
            }
            
            guard let finalCall = metadata["finalCall"] as? Bool else {
                completion(nil, callError ?? YTSError.invalidDataReceived)
                return
            }
            
            var newLastLoadedDocumentID = metadata["lastLoadedDocID"] as? FirestoreID
            
            if newLastLoadedDocumentID == nil && lastLoadedDocumentID != nil {
                print("This isn't supposed to happen, the sequential loader would run in circles. Correcting by preserving old 'lastLoadedDocumentID'.")
                newLastLoadedDocumentID = lastLoadedDocumentID
            }
            
            let group = DispatchGroup()
            
            for _ in imageDocuments {
                group.enter()
            }
            
            for imageDoc in imageDocuments {
                guard let urlString = imageDoc["url"] as? String,
                      let url = URL(string: urlString),
                      let uploadDict = imageDoc["uploaded"] as? [String: Int],
                      let uploaded = Date(firebaseTimestampDictionary: uploadDict)
                else {
                    print("Skipping this element, data invalid.")
                    group.leave()
                    continue
                }
                
                let title = imageDoc["title"] as? String
                
                let slideshowImage = SlideshowImage(url: url, name: title, uploaded: uploaded)
                images.append(slideshowImage)
                group.leave()
                continue
            }
            
            group.notify(queue: .main) {
                completion((images: images, metadata: (newLastLoadedDocumentID: newLastLoadedDocumentID, finalCall: finalCall)), callError)
            }
        }
    }
    
    /// Searches Firestore using the `search` cloud function
    /// - Parameters:
    ///   - query: The text to query for.
    ///   - completion: Callback which returns the results and metadata once function completes, including the new `lastLoadedDocumentID`.
    /// - Returns:
    /// `((results: Content, [Rabbi], Metadata)?, Error?)`
    static func search(query: String, contentOptions: ContentOptions = (limit: 5, includeThumbnailURLs: true, includeDetailedAuthors: false, startAfterDocumentID: nil), rebbeimOptions: RebbeimOptions = (limit: 10, includePictureURLs: false, startAfterDocumentID: nil), completion: @escaping (_ results: (content: (Content?), rebbeim: [Rabbi]?, metadata: (content: Metadata?, rebbeim: Metadata?))?, _ error: Error?) -> Void) {
        var content: Content = (videos: [], audios: [])
        var rebbeim: [Rabbi] = []
        
        var contentOptionsData: [String : Any] = [
            "limit": contentOptions.limit,
            "includeThumbnailURLs": contentOptions.includeThumbnailURLs,
            "includeDetailedAuthorInfo": contentOptions.includeDetailedAuthors
        ]
        
        if let csID = contentOptions.startAfterDocumentID {
            contentOptionsData["startAfterDocumentID"] = csID
        }
        
        var rebbeimOptionsData: [String : Any] = [
            "limit": rebbeimOptions.limit,
            "includePictureURLs": rebbeimOptions.includePictureURLs
        ]
        
        if let rsID = rebbeimOptions.startAfterDocumentID {
            rebbeimOptionsData["startAfterDocumentID"] = rsID
        }
        
        var contentData: [String: Any] = [
            "limit": contentOptions.limit,
            "includeThumbnailURLs": contentOptions.includeThumbnailURLs,
            "includeDetailedAuthorInfo": contentOptions.includeDetailedAuthors
        ]
        
        if let contentStartDocID = contentOptions.startAfterDocumentID {
            contentData["startAfterDocumentID"] = contentStartDocID
        }
        
        var rebbeimData: [String: Any] = [
            "limit": rebbeimOptions.limit,
            "includePictureURLs": rebbeimOptions.includePictureURLs
        ]
        
        if let rebbeimStartDocID = rebbeimOptions.startAfterDocumentID {
            rebbeimData["startAfterDocumentID"] = rebbeimStartDocID
        }
        
        let data: [String: Any] = [
            "searchQuery": query,
            "searchOptions": [
                "content": contentData,
                "rebbeim": rebbeimData
            ],
        ]
        
        let httpsCallable = functions.httpsCallable("search")
        httpsCallable.call(data) { callResult, callError in
            // Check if there was any data received
            guard let response = callResult?.data as? [String: Any] else {
                completion(nil, callError ?? YTSError.noDataReceived)
                return
            }
            
            guard let results = response["results"] as? [String: Any] else {
                completion(nil, callError ?? YTSError.invalidDataReceived)
                return
            }
            
            guard let metadata = response["metadata"] as? [String: Any], let contentMetadata = metadata["content"] as? [String: Any], let rebbeimMetadata = metadata["rebbeim"] as? [String: Any] else {
                completion(nil, callError ?? YTSError.invalidDataReceived)
                return
            }
            
            let group = DispatchGroup()
            
            var finalCallContent: Bool?
            var newLastLoadedContentID: FirestoreID?
            
            if contentOptions.limit > 0 {
                guard let fcc = contentMetadata["finalCall"] as? Bool else {
                    completion(nil, callError ?? YTSError.invalidDataReceived)
                    return
                }
                finalCallContent = fcc
                
                let newLastID = contentMetadata["lastLoadedDocID"] as? FirestoreID
                newLastLoadedContentID = newLastID
                
                guard let contentDocuments = results["content"] as? [[String: Any]] else {
                    completion(nil, callError ?? YTSError.invalidDataReceived)
                    return
                }
                
                for _ in contentDocuments {
                    group.enter()
                }
                
                for contentDocument in contentDocuments {
                    guard let id = contentDocument["id"] as? FirestoreID, let title = contentDocument["title"] as? String, let description = contentDocument["description"] as? String, let dateDictionary = contentDocument["date"] as? [String: Int], let type = contentDocument["type"] as? String, let author = contentDocument["author"] as? [String: Any], let sourceURLString = contentDocument["source_url"] as? String else {
                        print("Document missing sufficient data. Continuing to next document.")
                        group.leave()
                        continue
                    }
                    
                    guard let sourceURL = URL(string: sourceURLString) else {
                        print("Source URL is invalid. Continuing to next document.")
                        group.leave()
                        continue
                    }
                    
                    let duration: TimeInterval? = (contentDocument["duration"] as? NSNumber)?.doubleValue
                    
                    guard let date = Date(firebaseTimestampDictionary: dateDictionary) else {
                        print("Invalid date value. Exiting scope.")
                        group.leave()
                        continue
                    }
                    
                    guard let authorID = author["id"] as? FirestoreID, let authorName = author["name"] as? String else {
                        print("Invalid author value. Exiting scope.")
                        group.leave()
                        continue
                    }
                    
                    switch type {
                    case "video":
                        let rabbi: Rabbi
                        if contentOptions.includeDetailedAuthors {
                            guard let authorProfilePictureURLString = author["profile_picture_url"] as? String, let authorProfilePictureURL = URL(string: authorProfilePictureURLString) else {
                                print("Author profile picture URL is invalid, continuing to next document.")
                                group.leave()
                                continue
                            }
                            rabbi = DetailedRabbi(id: authorID, name: authorName, profileImageURL: authorProfilePictureURL)
                        } else {
                            rabbi = Rabbi(id: authorID, name: authorName)
                        }
                        
                        content.videos.append(Video(
                            id: id,
                            sourceURL: sourceURL,
                            title: title,
                            author: rabbi,
                            description: description,
                            date: date,
                            duration: duration,
                            tags: []))
                        group.leave()
                        continue
                    case "audio":
                        let rabbi: Rabbi
                        if contentOptions.includeDetailedAuthors {
                            guard let authorProfilePictureURLString = author["profile_picture_url"] as? String, let authorProfilePictureURL = URL(string: authorProfilePictureURLString) else {
                                print("Author profile picture URL is invalid, continuing to next document.")
                                group.leave()
                                continue
                            }
                            rabbi = DetailedRabbi(id: authorID, name: authorName, profileImageURL: authorProfilePictureURL)
                        } else {
                            rabbi = Rabbi(id: authorID, name: authorName)
                        }
                        content.audios.append(Audio(
                            id: id,
                            sourceURL: sourceURL,
                            title: title,
                            author: rabbi,
                            description: description,
                            date: date,
                            duration: duration,
                            tags: []))
                        group.leave()
                        continue
                    default:
                        print("Type unrecognized.")
                        group.leave()
                        continue
                    }
                }
            }
            
            var finalCallRabbi: Bool?
            var newLastLoadedRabbiID: FirestoreID?
            
            if rebbeimOptions.limit > 0 {
                guard let fcr = rebbeimMetadata["finalCall"] as? Bool else {
                    completion(nil, callError ?? YTSError.invalidDataReceived)
                    return
                }
                finalCallRabbi = fcr
                
                let newLastID = rebbeimMetadata["lastLoadedDocID"] as? FirestoreID
                newLastLoadedRabbiID = newLastID
                
                guard let rabbiDocuments = results["rebbeim"] as? [[String: Any]] else {
                    completion(nil, callError ?? YTSError.invalidDataReceived)
                    return
                }
                
                for _ in rabbiDocuments {
                    group.enter()
                }
                
                for rabbiDocument in rabbiDocuments {
                    guard let id = rabbiDocument["id"] as? FirestoreID, let name = rabbiDocument["name"] as? String else {
                        print("Document missing sufficient data. Continuing to next document.")
                        group.leave()
                        continue
                    }
                    
                    if rebbeimOptions.includePictureURLs {
                        if let profilePictureURLString = rabbiDocument["profile_picture_url"] as? String, let profilePictureURL = URL(string: profilePictureURLString) {
                            rebbeim.append(DetailedRabbi(id: id, name: name, profileImageURL: profilePictureURL))
                            group.leave()
                            continue
                        } else {
                            print("Picture URL requested but not returned; skipping this Rabbi.")
                            group.leave()
                            continue
                        }
                    } else {
                        rebbeim.append(Rabbi(id: id, name: name))
                        group.leave()
                        continue
                    }
                }
            }
            
            group.notify(queue: .main) {
                var cm: Metadata?
                if contentOptions.limit > 0, let finalCallContent = finalCallContent {
                    cm = (newLastLoadedDocumentID: newLastLoadedContentID, finalCall: finalCallContent)
                } else {
                    cm = nil
                }
                
                var rm: Metadata?
                if rebbeimOptions.limit > 0, let finalCallRabbi = finalCallRabbi {
                    rm = (newLastLoadedDocumentID: newLastLoadedRabbiID, finalCall: finalCallRabbi)
                } else {
                    rm = nil
                }
                
                completion((content: content, rebbeim: rebbeim, metadata: (content: cm, rebbeim: rm)), callError)
            }
        }
    }
    
    /// Loads `Rabbi` objects from Firestore.
    /// - Parameters:
    ///   - lastLoadedDocumentID: Pages results starting from first element afterwards.
    ///   - count: The amount of `Rabbi` objects to return. Default is `10`.
    ///   - includeProfilePictureURLs: Whether or not to include profile picture URLs in the response. Default is `true`.
    ///   - completion: Callback which returns the results and metadata once function completes, including the new `lastLoadedDocumentID`.
    static func loadRebbeim(options: RebbeimOptions = (limit: 10, includePictureURLs: true, startAfterDocumentID: nil), completion: @escaping (_ results: (rebbeim: [Rabbi], metadata: Metadata)?, _ error: Error?) -> Void) {
        var rebbeim: [Rabbi] = []
        
        var data: [String: Any] = [
            "limit": options.limit,
            "includePictureURLs": options.includePictureURLs
        ]
        if let startAfterDocumentID = options.startAfterDocumentID {
            data["lastLoadedDocID"] = startAfterDocumentID
        }
        
        let httpsCallable = functions.httpsCallable("loadRebbeim")
        
        httpsCallable.call(data) { callResult, callError in
            guard let response = callResult?.data as? [String: Any] else {
                completion(nil, callError ?? YTSError.noDataReceived)
                return
            }
            
            guard let rabbiDocuments = response["results"] as? [[String: Any]], let metadata = response["metadata"] as? [String: Any] else {
                completion(nil, callError ?? YTSError.invalidDataReceived)
                return
            }
            
            var newLastLoadedDocumentID = metadata["lastLoadedDocID"] as? FirestoreID
            
            if newLastLoadedDocumentID == nil && options.startAfterDocumentID != nil {
                print("This isn't supposed to happen, the sequential loader would run in circles. Correcting by preserving old 'options.startAfterDocumentID'.")
                newLastLoadedDocumentID = options.startAfterDocumentID
            }
            
            guard let finalCall = metadata["finalCall"] as? Bool else {
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
                
                if options.includePictureURLs {
                    if let profilePictureURLString = rabbiDocument["profile_picture_url"] as? String, let profilePictureURL = URL(string: profilePictureURLString) {
                        rebbeim.append(DetailedRabbi(id: id, name: name, profileImageURL: profilePictureURL))
                        group.leave()
                        continue
                    } else {
                        print("Document missing sufficient data. Continuing to next document.")
                        group.leave()
                        continue
                    }
                } else {
                    rebbeim.append(Rabbi(id: id, name: name))
                    group.leave()
                    continue
                }
            }
            
            group.notify(queue: .main) {
                completion((rebbeim: rebbeim, metadata: (newLastLoadedDocumentID: newLastLoadedDocumentID, finalCall: finalCall)), callError)
            }
        }
    }
    
    private static func contentClosure(options: ContentOptions, completion: @escaping (_ results: (content: Content, metadata: Metadata)?, _ error: Error?) -> Void) -> ((HTTPSCallableResult?, Error?) -> Void) {
        var content: Content = (videos: [], audios: [])
        
        return { callResult, callError in
            guard let response = callResult?.data as? [String: Any] else {
                completion(nil, callError ?? YTSError.noDataReceived)
                return
            }
            
            guard let contentDocuments = response["results"] as? [[String: Any]], let metadata = response["metadata"] as? [String: Any] else {
                completion(nil, callError ?? YTSError.invalidDataReceived)
                return
            }
            
            guard let finalCall = metadata["finalCall"] as? Bool else {
                completion(nil, callError ?? YTSError.invalidDataReceived)
                return
            }
            var newLastLoadedDocumentID = metadata["lastLoadedDocID"] as? FirestoreID
            
            if newLastLoadedDocumentID == nil && options.startAfterDocumentID != nil {
                print("This isn't supposed to happen, the sequential loader would run in circles. Correcting by preserving old 'options.startAfterDocumentID'.")
                newLastLoadedDocumentID = options.startAfterDocumentID
            }
            
            let group = DispatchGroup()
            
            for _ in contentDocuments {
                group.enter()
            }
            
            for contentDocument in contentDocuments {
                guard let id = contentDocument["id"] as? FirestoreID, let fileID = contentDocument["fileID"] as? FileID, let title = contentDocument["title"] as? String, let description = contentDocument["description"] as? String, let dateDictionary = contentDocument["date"] as? [String: Int], let type = contentDocument["type"] as? String, let author = contentDocument["author"] as? [String: Any], let sourceURLString = contentDocument["source_url"] as? String else {
                    print("Document missing sufficient data. Continuing to next document.")
                    group.leave()
                    continue
                }
                
                guard let sourceURL = URL(string: sourceURLString) else {
                    print("Source URL is invalid. Continuing to next document.")
                    group.leave()
                    continue
                }
                
                let duration: TimeInterval? = (contentDocument["duration"] as? NSNumber)?.doubleValue
                
                guard let date = Date(firebaseTimestampDictionary: dateDictionary) else {
                    print("Invalid date value. Exiting scope.")
                    group.leave()
                    continue
                }
                
                guard let authorID = author["id"] as? FirestoreID, let authorName = author["name"] as? String else {
                    print("Invalid author value. Exiting scope.")
                    group.leave()
                    continue
                }
                
                switch type {
                case "video":
                    let rabbi: Rabbi
                    
                    if options.includeDetailedAuthors {
                        guard let authorProfilePictureURLString = author["profile_picture_url"] as? String, let authorProfilePictureURL = URL(string: authorProfilePictureURLString) else {
                            print("Author profile picture URL is invalid, continuing to next document.")
                            group.leave()
                            continue
                        }
                        rabbi = DetailedRabbi(id: authorID, name: authorName, profileImageURL: authorProfilePictureURL)
                    } else {
                        rabbi = Rabbi(id: authorID, name: authorName)
                    }
                    
                    content.videos.append(Video(
                        id: id,
                        fileID: fileID,
                        sourceURL: sourceURL,
                        title: title,
                        author: rabbi,
                        description: description,
                        date: date,
                        duration: duration,
                        tags: []))
                    group.leave()
                    continue
                case "audio":
                    let rabbi: Rabbi
                    if options.includeDetailedAuthors {
                        guard let authorProfilePictureURLString = author["profile_picture_url"] as? String, let authorProfilePictureURL = URL(string: authorProfilePictureURLString) else {
                            print("Author profile picture URL is invalid, continuing to next document.")
                            group.leave()
                            continue
                        }
                        
                        rabbi = DetailedRabbi(id: authorID, name: authorName, profileImageURL: authorProfilePictureURL)
                    } else {
                        rabbi = Rabbi(id: authorID, name: authorName)
                    }
                    
                    content.audios.append(Audio(
                        id: id,
                        fileID: fileID,
                        sourceURL: sourceURL,
                        title: title,
                        author: rabbi,
                        description: description,
                        date: date,
                        duration: duration,
                        tags: []))
                    group.leave()
                    continue
                default:
                    print("Type unrecognized.")
                    group.leave()
                    continue
                }
            }
            
            group.notify(queue: .main) {
                completion((content: content, metadata: (newLastLoadedDocumentID: newLastLoadedDocumentID, finalCall: finalCall)), callError)
            }
        }
    }
    
    /// Loads `YTSContent` objects from Firestore.
    /// - Parameters:
    ///   - lastLoadedDocumentID: Pages results starting from first element afterwards.
    ///   - requestedCount: The amount of `YTSContent` objects to return. Default is `10`.
    ///   - includeThumbnailURLs: Whether or not to include thumbnail URLs in the response.
    ///   - includeAllAuthorData: Whether or not to include extra author data, such as  profile picture URLs, in the response. Default is `false`.
    ///   - completion: Callback which returns the results and metadata once function completes, including the new `lastLoadedDocumentID`.
    static func loadContent(options: ContentOptions = (limit: 10, includeThumbnailURLs: true, includeDetailedAuthors: false, startAfterDocumentID: nil), completion: @escaping (_ results: (content: Content, metadata: Metadata)?, _ error: Error?) -> Void) {
        var data: [String: Any] = [
            "limit": options.limit,
            "includeThumbnailURLs": options.includeThumbnailURLs,
            "includeAllAuthorData": options.includeDetailedAuthors
        ]
        if let startAfterDocumentID = options.startAfterDocumentID {
            data["lastLoadedDocID"] = startAfterDocumentID
        }
        
        let httpsCallable = functions.httpsCallable("loadContent")
        
        httpsCallable.call(data, completion: contentClosure(options: options, completion: completion))
    }
    
    /// Loads `YTSContent` objects from Firestore.
    /// - Parameters:
    ///   - lastLoadedDocumentID: Pages results starting from first element afterwards.
    ///   - requestedCount: The amount of `YTSContent` objects to return. Default is `10`.
    ///   - includeThumbnailURLs: Whether or not to include thumbnail URLs in the response.
    ///   - includeAllAuthorData: Whether or not to include extra author data, such as  profile picture URLs, in the response. Default is `false`.
    ///   - completion: Callback which returns the results and metadata once function completes, including the new `lastLoadedDocumentID`.
    ///   - attributionRabbi: The function only returns content attributed to the `Rabbi` object.
    static func loadContent(options: ContentOptions = (limit: 10, includeThumbnailURLs: true, includeDetailedAuthors: false, startAfterDocumentID: nil), matching rabbi: Rabbi, completion: @escaping (_ results: (content: Content, metadata: (newLastLoadedDocumentID: FirestoreID?, finalCall: Bool))?, _ error: Error?) -> Void) {
        print("Loading content...")
        var data: [String: Any] = [
            "limit": options.limit,
            "includeThumbnailURLs": options.includeThumbnailURLs,
            "includeAllAuthorData": options.includeDetailedAuthors,
            "search": ["field": "attributionID",
                       "value": rabbi.firestoreID]
        ]
        if let startAfterDocumentID = options.startAfterDocumentID {
            data["lastLoadedDocID"] = startAfterDocumentID
        }
    
        let httpsCallable = functions.httpsCallable("loadContent")
        
        httpsCallable.call(data, completion: contentClosure(options: options, completion: completion))
    }
    
    
    /// Loads `YTSContent` objects from Firestore.
    /// - Parameters:
    ///   - lastLoadedDocumentID: Pages results starting from first element afterwards.
    ///   - requestedCount: The amount of `YTSContent` objects to return. Default is `10`.
    ///   - includeThumbnailURLs: Whether or not to include thumbnail URLs in the response.
    ///   - includeAllAuthorData: Whether or not to include extra author data, such as  profile picture URLs, in the response. Default is `false`.
    ///   - completion: Callback which returns the results and metadata once function completes, including the new `lastLoadedDocumentID`.
    ///   - matchingTag: The function only returns content that have a tag matching  the `Tag` object.
    static func loadContent(options: ContentOptions = (limit: 10, includeThumbnailURLs: true, includeDetailedAuthors: false, startAfterDocumentID: nil), matching tag: Tag, completion: @escaping (_ results: (content: Content, metadata: (newLastLoadedDocumentID: FirestoreID?, finalCall: Bool))?, _ error: Error?) -> Void) {
        var data: [String: Any] = [
            "limit": options.limit,
            "search": ["field": "tag", "value": tag.name.lowercased()],
            "includeThumbnailURLs": options.includeThumbnailURLs,
            "includeAllAuthorData": options.includeDetailedAuthors
        ]
        if let startAfterDocumentID = options.startAfterDocumentID {
            data["lastLoadedDocID"] = startAfterDocumentID
        }
    
        let httpsCallable = functions.httpsCallable("loadContent")
        
        httpsCallable.call(data, completion: contentClosure(options: options, completion: completion))
    }
}

extension Date {
    init?(firebaseTimestampDictionary: [String: Int]) {
        guard let seconds = firebaseTimestampDictionary["_seconds"] else {
            return nil
        }
        guard let nanoseconds = firebaseTimestampDictionary["_nanoseconds"] else {
            return nil
        }
        
        let timestamp = Timestamp(seconds: Int64(seconds), nanoseconds: Int32(nanoseconds))
        self = timestamp.dateValue()
    }
}
