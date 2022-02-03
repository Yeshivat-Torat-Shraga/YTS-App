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
    
    typealias ContentOptions = (limit: Int, includeThumbnailURLs: Bool, includeDetailedAuthors: Bool, startFromDocumentID: FirestoreID?)
    typealias RebbeimOptions = (limit: Int, includePictureURLs: Bool, startFromDocumentID: FirestoreID?)
    
    typealias Metadata = (newLastLoadedDocumentID: FirestoreID?, includesLastElement: Bool)
    
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
            guard let urlDocuments = response["content"] as? [[String: Any]] else {
                completion(nil, callError ?? YTSError.invalidDataReceived)
                return
            }
            let includesLastElement = response["includesLastElement"] as? Bool ?? true
            let newLastLoadedDocumentID = response["lastLoadedDocID"] as? FirestoreID
            
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
                completion((articles: articles, metadata: (newLastLoadedDocumentID: newLastLoadedDocumentID, includesLastElement: includesLastElement)), callError)
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
            guard let imageDocuments = response["results"] as? [[String: Any]], let metadata = response["metadata"] as? [String: Any] else {
                completion(nil, callError ?? YTSError.invalidDataReceived)
                return
            }
            
            guard let includesLastElement = metadata["includesLastElement"] as? Bool else {
                completion(nil, callError ?? YTSError.invalidDataReceived)
                return
            }
            
            let newLastLoadedDocumentID = metadata["lastLoadedDocID"] as? FirestoreID
            
            let group = DispatchGroup()
            
            for _ in imageDocuments {
                group.enter()
            }
            
            for imageDoc in imageDocuments {
                guard let urlString = imageDoc["url"] as? String, let url = URL(string: urlString), let uploadDict = imageDoc["uploaded"] as? [String: Int], let uploaded = Date(firebaseTimestampDictionary: uploadDict) else {
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
                completion((images: images, metadata: (newLastLoadedDocumentID: newLastLoadedDocumentID, includesLastElement: includesLastElement)), callError)
            }
        }
    }
    
    /// Searches Firestore using the `search` cloud function
    /// - Parameters:
    ///   - query: The text to query for.
    ///   - completion: Callback which returns the results and metadata once function completes, including the new `lastLoadedDocumentID`.
    /// - Returns:
    /// `((results: Content, [Rabbi], Metadata)?, Error?)`
    static func search(query: String, contentOptions: ContentOptions = (limit: 10, includeThumbnailURLs: true, includeDetailedAuthors: false, startFromDocumentID: nil), rebbeimOptions: RebbeimOptions = (limit: 10, includePictureURLs: false, startFromDocumentID: nil), completion: @escaping (_ results: (content: (Content), rebbeim: [Rabbi], metadata: (content: Metadata, rebbeim: Metadata))?, _ error: Error?) -> Void) {
        var content: Content = (videos: [], audios: [])
        var rebbeim: [Rabbi] = []
        
        var contentOptionsData: [String : Any] = [
            "limit": contentOptions.limit,
            "includeThumbnailURLs": contentOptions.includeThumbnailURLs,
            "includeDetailedAuthorInfo": contentOptions.includeDetailedAuthors
        ]
        
        if let csID = contentOptions.startFromDocumentID {
            contentOptionsData["startFromDocumentID"] = csID
        }
        
        var rebbeimOptionsData: [String : Any] = [
            "limit": rebbeimOptions.limit,
            "includePictureURLs": rebbeimOptions.includePictureURLs
        ]
        
        if let rsID = rebbeimOptions.startFromDocumentID {
            rebbeimOptionsData["startFromDocumentID"] = rsID
        }
        
        let data: [String: Any] = [
            "searchQuery": query,
            "searchOptions": [
                "content": contentOptions,
                "rebbeim": rebbeimOptions
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
            
            // Check if response contains valid data
            guard let rabbiDocuments = results["rebbeim"] as? [[String: Any]], let contentDocuments = results["content"] as? [[String: Any]] else {
                completion(nil, callError ?? YTSError.invalidDataReceived)
                return
            }
            
            guard let metadata = response["metadata"] as? [String: Any], let contentMetadata = metadata["content"] as? [String: Any], let rebbeimMetadata = metadata["rebbeim"] as? [String: Any] else {
                completion(nil, callError ?? YTSError.invalidDataReceived)
                return
            }
            
            
            guard let includesLastContent = contentMetadata["includesLastElement"] as? Bool, let includesLastRabbi = rebbeimMetadata["includesLastElement"] as? Bool else {
                completion(nil, callError ?? YTSError.invalidDataReceived)
                return
            }
            
            let newLastLoadedContentID = contentMetadata["lastLoadedDocumentID"] as? FirestoreID
            let newLastLoadedRabbiID = rebbeimMetadata["lastLoadedDocumentID"] as? FirestoreID
            
            let group = DispatchGroup()
            
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
            
            group.notify(queue: .main) {
                completion((content: content, rebbeim: rebbeim, metadata: (content: (newLastLoadedDocumentID: newLastLoadedContentID, includesLastElement: includesLastContent), rebbeim: (newLastLoadedDocumentID: newLastLoadedRabbiID, includesLastElement: includesLastRabbi))), callError)
            }
        }
    }
    
    /// Loads `Rabbi` objects from Firestore.
    /// - Parameters:
    ///   - lastLoadedDocumentID: Pages results starting from first element afterwards.
    ///   - count: The amount of `Rabbi` objects to return. Default is `10`.
    ///   - includeProfilePictureURLs: Whether or not to include profile picture URLs in the response. Default is `true`.
    ///   - completion: Callback which returns the results and metadata once function completes, including the new `lastLoadedDocumentID`.
    static func loadRebbeim(options: RebbeimOptions = (limit: 10, includePictureURLs: true, startFromDocumentID: nil), completion: @escaping (_ results: (rebbeim: [Rabbi], metadata: Metadata)?, _ error: Error?) -> Void) {
        var rebbeim: [Rabbi] = []
        
        var data: [String: Any] = [
            "limit": options.limit,
            "includePictureURLs": options.includePictureURLs
        ]
        if let startFromDocumentID = options.startFromDocumentID {
            data["lastLoadedDocID"] = startFromDocumentID
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
            
            let newLastLoadedDocumentID = metadata["lastLoadedDocID"] as? FirestoreID
            
            guard let includesLastElement = metadata["includesLastElement"] as? Bool else {
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
                completion((rebbeim: rebbeim, metadata: (newLastLoadedDocumentID: newLastLoadedDocumentID, includesLastElement: includesLastElement)), callError)
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
        
        guard let contentDocuments = response["content"] as? [[String: Any]], let metadata = response["metadata"] as? [String: Any] else {
            completion(nil, callError ?? YTSError.invalidDataReceived)
            return
        }
        
            guard let includesLastElement = metadata["includesLastElement"] as? Bool else {
                completion(nil, callError ?? YTSError.invalidDataReceived)
                return
            }
        let newLastLoadedDocumentID = metadata["lastLoadedDocumentID"] as? FirestoreID
        
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
            completion((content: content, metadata: (newLastLoadedDocumentID: newLastLoadedDocumentID, includesLastElement: includesLastElement)), callError)
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
    static func loadContent(options: ContentOptions = (limit: 10, includeThumbnailURLs: true, includeDetailedAuthors: false, startFromDocumentID: nil), completion: @escaping (_ results: (content: Content, metadata: Metadata)?, _ error: Error?) -> Void) {
        var data: [String: Any] = [
            "limit": options.limit,
            "includeThumbnailURLs": options.includeThumbnailURLs,
            "includeAllAuthorData": options.includeDetailedAuthors
        ]
        if let startFromDocumentID = options.startFromDocumentID {
            data["lastLoadedDocID"] = startFromDocumentID
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
    static func loadContent(options: ContentOptions = (limit: 10, includeThumbnailURLs: true, includeDetailedAuthors: false, startFromDocumentID: nil), matching rabbi: Rabbi, completion: @escaping (_ results: (content: Content, metadata: (newLastLoadedDocumentID: FirestoreID?, includesLastElement: Bool))?, _ error: Error?) -> Void) {
        var data: [String: Any] = [
            "limit": options.limit,
            "includeThumbnailURLs": options.includeThumbnailURLs,
            "includeAllAuthorData": options.includeDetailedAuthors,
            "search": ["field": "attributionID",
                       "value": rabbi.firestoreID]
        ]
        if let startFromDocumentID = options.startFromDocumentID {
            data["lastLoadedDocID"] = startFromDocumentID
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
    static func loadContent(options: ContentOptions = (limit: 10, includeThumbnailURLs: true, includeDetailedAuthors: false, startFromDocumentID: nil), matching tag: Tag, completion: @escaping (_ results: (content: Content, metadata: (newLastLoadedDocumentID: FirestoreID?, includesLastElement: Bool))?, _ error: Error?) -> Void) {
        var data: [String: Any] = [
            "limit": options.limit,
            "search": ["field": "tag", "value": tag.name],
            "includeThumbnailURLs": options.includeThumbnailURLs,
            "includeAllAuthorData": options.includeDetailedAuthors
        ]
        if let startFromDocumentID = options.startFromDocumentID {
            data["lastLoadedDocID"] = startFromDocumentID
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
