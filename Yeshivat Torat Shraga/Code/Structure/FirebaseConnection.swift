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
    
    static func loadNews(
        lastLoadedDocumentID: FirestoreID? = nil,
        limit: Int = 15,
        completion: @escaping (
            _ results: (
                articles: [NewsArticle],
                metadata: (
                    newLastLoadedDocumentID: FirestoreID?,
                    includesLastElement: Bool
                )
            )?, _ error: Error?) -> Void
    ) {
        var articles: [NewsArticle] = []
        let httpsCallable = functions.httpsCallable("loadNews")
        var data: [String: Any] = [
            "count": limit
        ]
        if let lastLoadedDocumentID = lastLoadedDocumentID {
            data["lastLoadedDocumentID"] = lastLoadedDocumentID
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
            let newLastLoadedDocumentID = response["lastLoadedDocumentID"] as? FirestoreID
            
            let group = DispatchGroup()
            for _ in urlDocuments {
                group.enter()
            }
            
            for document in urlDocuments {

                guard let body       = document["body"]     as? String,
                      let title      = document["title"]    as? String,
                      let author     = document["author"]   as? String,
                      let uploadDict = document["uploaded"] as? [String: Int]
                else {
                    completion(nil, callError ?? YTSError.invalidDataReceived)
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
                
                let article = NewsArticle(
                    title: title,
                    body: body,
                    uploaded: uploaded,
                    author: author,
                    images: slideshow)
                articles.append(article)
                group.leave()
            }
            group.notify(queue: .main) {
                completion((articles: articles, metadata: (newLastLoadedDocumentID: newLastLoadedDocumentID, includesLastElement: includesLastElement)), callError)
            }
        }
    }
    
    
    static func loadSlideshowImages(
        lastLoadedDocumentID: FirestoreID? = nil,
        limit: Int,
        completion: @escaping (
            _ results: (
                images: [SlideshowImage],
                metadata: (
                    newLastLoadedDocumentID: FirestoreID?,
                    includesLastElement: Bool
                )
            )?, _ error: Error?) -> Void
    ) {
        var images: [SlideshowImage] = []
        let httpsCallable = functions.httpsCallable("loadSlideshow")
        var data: [String: Any] = [
            "count": limit
        ]
        if let lastLoadedDocumentID = lastLoadedDocumentID {
            data["lastLoadedDocumentID"] = lastLoadedDocumentID
        }
        httpsCallable.call(data) { callResult, callError in
            // Check if there was any data received
            guard let response = callResult?.data as? [String: Any] else {
                completion(nil, callError ?? YTSError.noDataReceived)
                return
            }
            
            // Check if response contains valid data
            guard let urlDocuments = response["content"] as? [[String: Any]],
                  let metadata     = response["metadata"] as? [String: Any]
            else {
                completion(nil, callError ?? YTSError.invalidDataReceived)
                return
            }
            let includesLastElement = metadata["includesLastElement"] as? Bool ?? true
            let newLastLoadedDocumentID = metadata["lastLoadedDocumentID"] as? FirestoreID
            
            for document in urlDocuments {
                guard let url = document["url"] as? String,
                      let uploadDict = document["uploaded"] as? [String: Int],
                      let uploaded = Date(firebaseTimestampDictionary: uploadDict)
                else {
                    completion(nil, callError ?? YTSError.invalidDataReceived)
                    return
                }
                let title = document["title"] as? String
                let urlObject = URL(string: url)
                let slideshowImage = SlideshowImage(url: urlObject!, name: title, uploaded: uploaded)
                images.append(slideshowImage)
            }
            completion((images: images, metadata: (newLastLoadedDocumentID: newLastLoadedDocumentID, includesLastElement: includesLastElement)), callError)
        }
    }
    
    /// Searches Firestore using the SearchFirestore cloud function
    /// - Parameters:
    ///   - query: The text to search Firestore for
    ///   - searchOptions: Controls how the search operates. Parameters are expected in the following structure:
    ///     - `content`: The options for searching through the content
    ///         - `limit`: The maximum number of results to return.
    ///         - `includeThumbnailURLs`: Whether or not to generate URLs for the thumbnails
    ///         - `includeDetailedAuthorInfo`: Whether or not to generate URLs for Author profile pictures
    ///         - `startFromDocumentID`: Firestore ID used for pagination
    ///     - `rebbeim`: The options for searching through the rebbeim
    ///         - `limit`: The maximum number of results to return.
    ///         - `includePictureURLs`: Whether or not to generate URLs for the profile pictures
    ///         - `startFromDocumentID`: Firestore ID used for pagination
    ///   - completion: Callback which returns the results and metadata once function completes, including the new `lastLoadedDocumentID`
    /// - Returns:
    /// ((`Content`, `[Rabbi]`)), metadata), `Error?`)
    ///

    static func searchFirestore(
        query: String,
        searchOptions: [String: Any],
        completion: @escaping (
            _ results: (
                contentAndRabbis: (content: Content, rebbeim: [Rabbi]),
                metadata: (
                    newLastLoadedDocumentID: FirestoreID?,
                    includesLastElement: Bool
                )
            )?, _ error: Error?) -> Void
    ) {
        // === Store results here: ===
        var content: Content = (videos: [], audios: [])
        var rebbeim: [Rabbi] = []
        
        // === Prepare data for Firebase function call ===
        let data: [String: Any] = [
            "searchQuery": query,
            "searchOptions": searchOptions
        ]
        
        // === Call the function ===
        let httpsCallable = functions.httpsCallable("searchFirestore")
        httpsCallable.call(data) { callResult, callError in
            // === Handle return data ===
            
            // Check if there was any data received
            guard let response = callResult?.data as? [String: Any] else {
                completion(nil, callError ?? YTSError.noDataReceived)
                return
            }
            
            // Check if response contains valid data
            guard let rabbiDocuments = response["rebbeim"] as? [[String: Any]],
                  let contentDocuments = response["content"] as? [[String: Any]],
                  let appliedSearchOptions = response["searchOptions"] as? [String: [String: Any]]
            else {
                completion(nil, callError ?? YTSError.invalidDataReceived)
                return
            }
            
            let includesLastElement = true//response["includesLastElement"] as? Bool,
            let newLastLoadedDocumentID = response["lastLoadedDocumentID"] as? FirestoreID
            
            let group = DispatchGroup()
            
            for _ in contentDocuments {
                group.enter()
            }
            
            for contentDocument in contentDocuments {
                guard let id = contentDocument["id"] as? FirestoreID,
                      let title = contentDocument["title"] as? String,
                      let description = contentDocument["description"] as? String,
                      let dateDictionary = contentDocument["date"] as? [String: Int],
                      let type = contentDocument["type"] as? String,
                      let author = contentDocument["author"] as? [String: Any],
                      let sourceURLString = contentDocument["source_url"] as? String
                else {
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
                
                guard let authorID = author["id"] as? FirestoreID,
                      let authorName = author["name"] as? String
                else {
                    print("Invalid author value. Exiting scope.")
                    group.leave()
                    continue
                }
                
                switch type {
                case "video":
                    let rabbi: Rabbi
                    if appliedSearchOptions["content"]!["includeDetailedAuthorInfo"] as! Bool == true {
                        guard let authorProfilePictureURLString = author["profile_picture_url"] as? String,
                              let authorProfilePictureURL = URL(string: authorProfilePictureURLString)
                        else {
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
                        tags: [],
                        thumbnail: Image("test-thumbnail")))
                    group.leave()
                    continue
                case "audio":
                    let rabbi: Rabbi
                    if appliedSearchOptions["content"]!["includeDetailedAuthorInfo"] as! Bool == true {
                        guard let authorProfilePictureURLString = author["profile_picture_url"] as? String,
                              let authorProfilePictureURL = URL(string: authorProfilePictureURLString)
                        else {
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
                guard let id = rabbiDocument["id"] as? FirestoreID,
                      let name = rabbiDocument["name"] as? String else {
                          print("Document missing sufficient data. Continuing to next document.")
                          group.leave()
                          continue
                      }

                if let profilePictureURLString = rabbiDocument["profile_picture_url"] as? String,
                   let profilePictureURL = URL(string: profilePictureURLString) {
                    rebbeim.append(DetailedRabbi(id: id, name: name, profileImageURL: profilePictureURL))
                    group.leave()
                    continue
                } else if let profilePictureFilename = rabbiDocument["profile_picture_filename"] as? String {
                    rebbeim.append(Rabbi(id: id, name: name))
                    print("""
                        /**
                        * No valid profile_picture_url was provided, but did receive a profile_picture_filename.
                        * As of now, there is no set way to handle that, so we are creating a NON-Detailed Rabbi
                        * object to store the data.
                        */
                        """)
                    group.leave()
                    continue
                } else {
                    print("No picture was given for this Rabbi.")
                    rebbeim.append(Rabbi(id: id, name: name))
                    group.leave()
                    continue
                }
            }
            
            group.notify(queue: .main) {
                completion((contentAndRabbis: (content: content,
                                               rebbeim: rebbeim),
                    metadata: (
                        newLastLoadedDocumentID: newLastLoadedDocumentID,
                        includesLastElement: includesLastElement)
                ), callError)
            }
        }
    }
    
    
    
    
    /// Loads `Rabbi` objects from Firestore.
    /// - Parameters:
    ///   - lastLoadedDocumentID: Pages results starting from first element afterwards.
    ///   - count: The amount of `Rabbi` objects to return. Default is `10`.
    ///   - includeProfilePictureURLs: Whether or not to include profile picture URLs in the response. Default is `true`.
    ///   - completion: Callback which returns the results and metadata once function completes, including the new `lastLoadedDocumentID`.
    static func loadRebbeim(
        lastLoadedDocumentID: FirestoreID? = nil,
        count requestedCount: Int = 10,
        includeProfilePictureURLs: Bool = true,
        completion: @escaping (
            _ results: (
                rebbeim: [Rabbi],
                metadata: (
                    newLastLoadedDocumentID: FirestoreID?,
                    includesLastElement: Bool
                )
            )?, _ error: Error?) -> Void
    ) {
        var rebbeim: [Rabbi] = []
        
        var data: [String: Any] = [
            "count": requestedCount,
            "includePictureURLs": includeProfilePictureURLs
        ]
        if let lastLoadedDocumentID = lastLoadedDocumentID {
            data["lastLoadedDocumentID"] = lastLoadedDocumentID
        }
        
        let httpsCallable = functions.httpsCallable("loadRebbeim")
        
        httpsCallable.call(data) { callResult, callError in
            guard let response = callResult?.data as? [String: Any] else {
                completion(nil, callError ?? YTSError.noDataReceived)
                return
            }
            
            guard let rabbiDocuments = response["content"] as? [[String: Any]],
                  let metadata       = response["metadata"] as? [String: Any]
            else {
                completion(nil, callError ?? YTSError.invalidDataReceived)
                return
            }
            
            let newLastLoadedDocumentID = metadata["lastLoadedDocumentID"] as? FirestoreID
            
            guard let includesLastElement = metadata["includesLastElement"] as? Bool else {
                completion(nil, callError ?? YTSError.invalidDataReceived)
                return
            }
            
            let group = DispatchGroup()
            
            for _ in rabbiDocuments {
                group.enter()
            }
            
            for rabbiDocument in rabbiDocuments {
                guard let id = rabbiDocument["id"] as? FirestoreID,
                      let name = rabbiDocument["name"] as? String else {
                          print("Document missing sufficient data. Continuing to next document.")
                          group.leave()
                          continue
                      }
                
                if let profilePictureURLString = rabbiDocument["profile_picture_url"] as? String,
                   let profilePictureURL = URL(string: profilePictureURLString) {
                    rebbeim.append(DetailedRabbi(id: id, name: name, profileImageURL: profilePictureURL))
                    group.leave()
                    continue
//                } else if let profilePictureFilename = rabbiDocument["profile_picture_filename"] as? String {
//                    fatalError("This feature has not been implemented")
                } else {
                    print("Document missing sufficient data. Continuing to next document.")
                    group.leave()
                    continue
                }
            }
            
            group.notify(queue: .main) {
                completion((rebbeim: rebbeim, metadata: (newLastLoadedDocumentID: newLastLoadedDocumentID, includesLastElement: includesLastElement)), callError)
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
    static func loadContent(lastLoadedDocumentID: FirestoreID? = nil,
                            count requestedCount: Int = 10,
                            includeThumbnailURLs: Bool,
                            includeAllAuthorData: Bool = false,
                            completion: @escaping (_ results: (content: Content, metadata: (newLastLoadedDocumentID: FirestoreID?, includesLastElement: Bool))?, _ error: Error?) -> Void) {
        var content: Content = (videos: [], audios: [])
        
        var data: [String: Any] = [
            "count": requestedCount,
            "includeThumbnailURLs": includeThumbnailURLs,
            "includeAllAuthorData": includeAllAuthorData
        ]
        if let lastLoadedDocumentID = lastLoadedDocumentID {
            data["lastLoadedDocumentID"] = lastLoadedDocumentID
        }
        
    
        let httpsCallable = functions.httpsCallable("loadContent")
        
        httpsCallable.call(data) { callResult, callError in
            guard let response = callResult?.data as? [String: Any] else {
                completion(nil, callError ?? YTSError.noDataReceived)
                return
            }
            
            guard let contentDocuments = response["content"] as? [[String: Any]],
                  let metadata = response["metadata"] as? [String: Any],
                  let includesLastElement = metadata["includesLastElement"] as? Bool
            else {
                completion(nil, callError ?? YTSError.invalidDataReceived)
                return
            }
            
            let newLastLoadedDocumentID = metadata["lastLoadedDocumentID"] as? FirestoreID
            
            
            let group = DispatchGroup()
            
            for _ in contentDocuments {
                group.enter()
            }
            
            for contentDocument in contentDocuments {
                guard let id = contentDocument["id"] as? FirestoreID, let fileID = contentDocument["fileID"] as? FileID,
                      let title = contentDocument["title"] as? String,
                      let description = contentDocument["description"] as? String,
                      let dateDictionary = contentDocument["date"] as? [String: Int],
                      let type = contentDocument["type"] as? String,
                      let author = contentDocument["author"] as? [String: Any],
                      let sourceURLString = contentDocument["source_url"] as? String else {
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
                
                guard let authorID = author["id"] as? FirestoreID,
                      let authorName = author["name"] as? String
                else {
                    print("Invalid author value. Exiting scope.")
                    group.leave()
                    continue
                }
                
                switch type {
                case "video":
                    let rabbi: Rabbi
                    if includeAllAuthorData {
                        guard let authorProfilePictureURLString = author["profile_picture_url"] as? String,
                              let authorProfilePictureURL = URL(string: authorProfilePictureURLString)
                        else {
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
                        tags: [],
                        thumbnail: Image("test-thumbnail")))
                    group.leave()
                    continue
                case "audio":
                    let rabbi: Rabbi
                    if includeAllAuthorData {
                        guard let authorProfilePictureURLString = author["profile_picture_url"] as? String,
                              let authorProfilePictureURL = URL(string: authorProfilePictureURLString)
                        else {
                            print("Author profile picture URL is invalid, continuing to next document.")
                            group.leave()
                            continue
                        }
                        rabbi = DetailedRabbi(
                            id: authorID,
                            name: authorName,
                            profileImageURL: authorProfilePictureURL)
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
    ///   - attributionRabbi: The function only returns content attributed to the `Rabbi` object.
    static func loadContent(lastLoadedDocumentID: FirestoreID? = nil,
                            count requestedCount: Int = 10,
                            attributionRabbi: Rabbi,
                            includeThumbnailURLs: Bool,
                            includeAllAuthorData: Bool = false,
                            completion: @escaping (_ results: (content: Content, metadata: (newLastLoadedDocumentID: FirestoreID?, includesLastElement: Bool))?, _ error: Error?) -> Void) {
        var content: Content = (videos: [], audios: [])
        
        var data: [String: Any] = [
            "count": requestedCount,
            "includeThumbnailURLs": includeThumbnailURLs,
            "includeAllAuthorData": includeAllAuthorData,
            "search": ["field": "attributionID",
                       "value": attributionRabbi.firestoreID]
        ]
        if let lastLoadedDocumentID = lastLoadedDocumentID {
            data["lastLoadedDocumentID"] = lastLoadedDocumentID
        }
        
    
        let httpsCallable = functions.httpsCallable("loadContent")
        
        httpsCallable.call(data) { callResult, callError in
            guard let response = callResult?.data as? [String: Any] else {
                completion(nil, callError ?? YTSError.noDataReceived)
                return
            }
            
            guard let contentDocuments = response["content"] as? [[String: Any]],
                  let metadata = response["metadata"] as? [String: Any],
                  let includesLastElement = metadata["includesLastElement"] as? Bool
            else {
                completion(nil, callError ?? YTSError.invalidDataReceived)
                return
            }
            
            let newLastLoadedDocumentID = metadata["lastLoadedDocumentID"] as? FirestoreID
            
            
            let group = DispatchGroup()
            
            for _ in contentDocuments {
                group.enter()
            }
            
            for contentDocument in contentDocuments {
                guard let id = contentDocument["id"] as? FirestoreID, let fileID = contentDocument["fileID"] as? FileID,
                      let title = contentDocument["title"] as? String,
                      let description = contentDocument["description"] as? String,
                      let dateDictionary = contentDocument["date"] as? [String: Int],
                      let type = contentDocument["type"] as? String,
                      let author = contentDocument["author"] as? [String: Any],
                      let sourceURLString = contentDocument["source_url"] as? String else {
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
                
                guard let authorID = author["id"] as? FirestoreID,
                      let authorName = author["name"] as? String
                else {
                    print("Invalid author value. Exiting scope.")
                    group.leave()
                    continue
                }
                
                switch type {
                case "video":
                    let rabbi: Rabbi
                    if includeAllAuthorData {
                        guard let authorProfilePictureURLString = author["profile_picture_url"] as? String,
                              let authorProfilePictureURL = URL(string: authorProfilePictureURLString)
                        else {
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
                        tags: [],
                        thumbnail: Image("test-thumbnail")))
                    group.leave()
                    continue
                case "audio":
                    let rabbi: Rabbi
                    if includeAllAuthorData {
                        guard let authorProfilePictureURLString = author["profile_picture_url"] as? String,
                              let authorProfilePictureURL = URL(string: authorProfilePictureURLString)
                        else {
                            print("Author profile picture URL is invalid, continuing to next document.")
                            group.leave()
                            continue
                        }
                        rabbi = DetailedRabbi(
                            id: authorID,
                            name: authorName,
                            profileImageURL: authorProfilePictureURL)
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
    ///   - matchingTag: The function only returns content that have a tag matching  the `Tag` object.
    static func loadContent(lastLoadedDocumentID: FirestoreID? = nil,
                            count requestedCount: Int = 10,
                            matchingTag: Tag,
                            includeThumbnailURLs: Bool,
                            includeAllAuthorData: Bool = false,
                            completion: @escaping (_ results: (content: Content, metadata: (newLastLoadedDocumentID: FirestoreID?, includesLastElement: Bool))?, _ error: Error?) -> Void) {
        var content: Content = (videos: [], audios: [])
        
        var data: [String: Any] = [
            "count": requestedCount,
            "search": ["field": "tag", "value": matchingTag.name],
            "includeThumbnailURLs": includeThumbnailURLs,
            "includeAllAuthorData": includeAllAuthorData
        ]
        if let lastLoadedDocumentID = lastLoadedDocumentID {
            data["lastLoadedDocumentID"] = lastLoadedDocumentID
        }
        
    
        let httpsCallable = functions.httpsCallable("loadContent")
        
        httpsCallable.call(data) { callResult, callError in
            guard let response = callResult?.data as? [String: Any] else {
                completion(nil, callError ?? YTSError.noDataReceived)
                return
            }
            
            guard let contentDocuments = response["content"] as? [[String: Any]],
                  let metadata = response["metadata"] as? [String: Any],
                  let includesLastElement = metadata["includesLastElement"] as? Bool
            else {
                completion(nil, callError ?? YTSError.invalidDataReceived)
                return
            }
            
            let newLastLoadedDocumentID = metadata["lastLoadedDocumentID"] as? FirestoreID
            
            
            let group = DispatchGroup()
            
            for _ in contentDocuments {
                group.enter()
            }
            
            for contentDocument in contentDocuments {
                guard let id = contentDocument["id"] as? FirestoreID, let fileID = contentDocument["fileID"] as? FileID,
                      let title = contentDocument["title"] as? String,
                      let description = contentDocument["description"] as? String,
                      let dateDictionary = contentDocument["date"] as? [String: Int],
                      let type = contentDocument["type"] as? String,
                      let author = contentDocument["author"] as? [String: Any],
                      let sourceURLString = contentDocument["source_url"] as? String else {
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
                
                guard let authorID = author["id"] as? FirestoreID,
                      let authorName = author["name"] as? String
                else {
                    print("Invalid author value. Exiting scope.")
                    group.leave()
                    continue
                }
                
                switch type {
                case "video":
                    let rabbi: Rabbi
                    if includeAllAuthorData {
                        guard let authorProfilePictureURLString = author["profile_picture_url"] as? String,
                              let authorProfilePictureURL = URL(string: authorProfilePictureURLString)
                        else {
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
                        tags: [],
                        thumbnail: Image("test-thumbnail")))
                    group.leave()
                    continue
                case "audio":
                    let rabbi: Rabbi
                    if includeAllAuthorData {
                        guard let authorProfilePictureURLString = author["profile_picture_url"] as? String,
                              let authorProfilePictureURL = URL(string: authorProfilePictureURLString)
                        else {
                            print("Author profile picture URL is invalid, continuing to next document.")
                            group.leave()
                            continue
                        }
                        rabbi = DetailedRabbi(
                            id: authorID,
                            name: authorName,
                            profileImageURL: authorProfilePictureURL)
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
