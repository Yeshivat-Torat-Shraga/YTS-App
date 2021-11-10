//
//  YTS.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 11/10/21.
//

import Foundation
import SwiftUI

typealias FirestoreID = String
typealias FileID = String

class Rabbi {
    var firestoreID: FirestoreID
    var name: String
    var profileImage: Image?
    var profileImageURL: URL?
    
    init(id firestoreID: FirestoreID, name: String, profileImage: Image) {
        self.firestoreID = firestoreID
        self.name = name
        self.profileImage = profileImage
    }
    
    init(id firestoreID: FirestoreID, name: String, profileImageURL: URL) {
        self.firestoreID = firestoreID
        self.name = name
        self.profileImageURL = profileImageURL
    }
    
    /*
    init?(name: String, profileImageURL: URL) throws {
        self.name = name
        do {
            let data = try Data(contentsOf: profileImageURL)
            guard let uiImage = UIImage(data: data) else {
                return nil
            }
            self.profileImage = Image(uiImage: uiImage)
        } catch {
            throw error
        }
    }
     */
    
}

typealias Tag = String

protocol YTSContent {
    var firestoreID: FirestoreID { get }
    var fileID: FileID { get }
    var sourceURL: URL { get }
    var title: String { get }
    var author: Rabbi { get }
    var description: String { get }
    var date: Date { get }
    var duration: TimeInterval { get }
    var tags: [Tag] { get }
}

class Video: YTSContent {
    internal var firestoreID: FirestoreID
    internal var fileID: FileID
    var sourceURL: URL
    var title: String
    var author: Rabbi
    var description: String
    var date: Date
    var duration: TimeInterval
    var tags: [Tag]
    
    var thumbnail: Image?
    var thumbnailURL: URL?
    
    init(id firestoreID: FirestoreID, fileID: FileID, sourceURL: URL, title: String, author: Rabbi, description: String, date: Date, duration: TimeInterval, tags: [Tag], thumbnail: Image) {
        self.firestoreID = firestoreID
        self.fileID = fileID
        self.sourceURL = sourceURL
        self.title = title
        self.author = author
        self.description = description
        self.date = date
        self.duration = duration
        self.tags = tags
        
        self.thumbnail = thumbnail
    }
    
    init(id firestoreID: FirestoreID, fileID: FileID, sourceURL: URL, title: String, author: Rabbi, description: String, date: Date, duration: TimeInterval, tags: [Tag], thumbnailURL: URL) {
        self.firestoreID = firestoreID
        self.fileID = fileID
        self.sourceURL = sourceURL
        self.title = title
        self.author = author
        self.description = description
        self.date = date
        self.duration = duration
        self.tags = tags
        
        self.thumbnailURL = thumbnailURL
    }
}

class Audio: YTSContent {
    internal var firestoreID: FirestoreID
    internal var fileID: FileID
    var sourceURL: URL
    var title: String
    var author: Rabbi
    var description: String
    var date: Date
    var duration: TimeInterval
    var tags: [Tag]
    
    init(id firestoreID: FirestoreID, fileID: FileID, sourceURL: URL, title: String, author: Rabbi, description: String, date: Date, duration: TimeInterval, tags: [Tag]) {
        self.firestoreID = firestoreID
        self.fileID = fileID
        self.sourceURL = sourceURL
        self.title = title
        self.author = author
        self.description = description
        self.date = date
        self.duration = duration
        self.tags = tags
    }
}

struct Category {
    var tag: Tag
    var icon: Image
}
