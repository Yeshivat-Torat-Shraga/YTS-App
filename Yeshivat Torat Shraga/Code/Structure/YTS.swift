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


class Rabbi: Hashable {
    /// The `FirestoreID` associated with this object in Firestore
    private var firestoreID: FirestoreID
    
    /// The name associated with this object
    var name: String
    
    init(id firestoreID: FirestoreID, name: String) {
        self.firestoreID = firestoreID
        self.name = name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(firestoreID)
    }
    
    static func == (lhs: Rabbi, rhs: Rabbi) -> Bool {
        lhs.firestoreID == rhs.firestoreID
    }
}

class DetailedRabbi: Rabbi, Tileable {
    /// The profile image associated with this object
    var profileImage: Image?
    
    /// The `URL` that links to  this object's profile image
    var profileImageURL: URL?
    
    var image: Image? {
        get {
            return self.profileImage
        }
        set {
            self.profileImage = newValue
        }
    }
    
    var imageURL: URL? {
        return profileImageURL
    }
    
    /// Standard initalizer used for a preexisting `Image`
    /// - Parameters:
    ///   - firestoreID: The `FirestoreID` associated with this object in Firestore
    ///   - name: The name associated with this object
    ///   - profileImage: The profile image associated with this object
    init(id firestoreID: FirestoreID, name: String, profileImage: Image) {
        super.init(id: firestoreID, name: name)
        self.profileImage = profileImage
    }
    
    /// Standard initalizer used when `URL` for a profile image is available and an `Image` is not
    /// - Parameters:
    ///   - firestoreID: The `FirestoreID` associated with this object in Firestore
    ///   - name: The name associated with this object
    ///   - profileImageURL: The `URL` that links to this object's profile image
    init(id firestoreID: FirestoreID, name: String, profileImageURL: URL) {
        super.init(id: firestoreID, name: name)
        self.profileImageURL = profileImageURL
    }
    
    static public var samples: [DetailedRabbi] = [
        DetailedRabbi(id: "INVALID ID", name: "Rabbi Shmuel Silber", profileImage: Image("SampleRabbi")),
        DetailedRabbi(id: "INVALID ID", name: "Rabbi Shmuel Silber", profileImage: Image("SampleRabbi")),
        DetailedRabbi(id: "INVALID ID", name: "Rabbi Shmuel Silber", profileImage: Image("SampleRabbi")),
        DetailedRabbi(id: "INVALID ID", name: "Rabbi Shmuel Silber", profileImage: Image("SampleRabbi")),
        DetailedRabbi(id: "INVALID ID", name: "Rabbi Shmuel Silber", profileImage: Image("SampleRabbi")),
    ]
    
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

/// A content object modeled like a Firestore content document
protocol YTSContent {
    /// The `FirestoreID` associated with this object in Firestore
    var firestoreID: FirestoreID { get }
    
    /// The `FileID` associated with this object's files in Firestore
    var fileID: FileID? { get }
    
    /// The `URL` that links to the source content
    var sourceURL: URL { get }
    
    /// The content title
    var title: String { get }
    
    /// The `Rabbi` object credited with authoring this object
    var author: Rabbi { get }
    
    /// The content description
    var description: String { get }
    
    /// The time that this content was uploaded to the server
    /// - Note: This date can be manually manipulated on the server end, so it may not be the actual upload date
    var date: Date { get }
    
    /// The duration of the content in seconds
    var duration: TimeInterval? { get }
    
    /// `Tag` references to this object's topics
    var tags: [Tag] { get }
}

class Video: YTSContent {
    internal var firestoreID: FirestoreID
    internal var fileID: FileID?
    var sourceURL: URL
    var title: String
    var author: Rabbi
    var description: String
    var date: Date
    var duration: TimeInterval?
    var tags: [Tag]
    
    var thumbnail: Image?
    var thumbnailURL: URL?
    
    /// Standard initializer for a `Video`
    /// - Parameters:
    ///   - firestoreID: The `FirestoreID` associated with this object in Firestore
    ///   - fileID: The `FileID` associated with this object's files in Firestore
    ///   - sourceURL: The `URL` that links to the source content
    ///   - title: The content title
    ///   - author: The `Rabbi` object credited with authoring this object
    ///   - description: The content description
    ///   - date: The time that this content was uploaded to the server
    ///   - duration: The duration of the content in seconds
    ///   - tags: `Tag` references to this object's topics
    ///   - thumbnail: The thumbnail associated with this content
    init(id firestoreID: FirestoreID, fileID: FileID? = nil, sourceURL: URL, title: String, author: Rabbi, description: String, date: Date, duration: TimeInterval?, tags: [Tag], thumbnail: Image) {
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
    
    /// Standard initializer for a `Video`
    /// - Parameters:
    ///   - firestoreID: The `FirestoreID` associated with this object in Firestore
    ///   - fileID: The `FileID` associated with this object's files in Firestore
    ///   - sourceURL: The `URL` that links to the source content
    ///   - title: The content title
    ///   - author: The `Rabbi` object credited with authoring this object
    ///   - description: The content description
    ///   - date: The time that this content was uploaded to the server
    ///   - duration: The duration of the content in seconds
    ///   - tags: `Tag` references to this object's topics
    ///   - thumbnailURL: The `URL` associated with this content's thumbnail image
    init(id firestoreID: FirestoreID, fileID: FileID? = nil, sourceURL: URL, title: String, author: Rabbi, description: String, date: Date, duration: TimeInterval?, tags: [Tag], thumbnailURL: URL) {
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
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(firestoreID)
    }
    
    static func == (lhs: Video, rhs: Video) -> Bool {
        lhs.firestoreID == rhs.firestoreID
    }
}

class Audio: YTSContent, Hashable {
    internal var firestoreID: FirestoreID
    internal var fileID: FileID?
    var sourceURL: URL
    var title: String
    var author: Rabbi
    var description: String
    var date: Date
    var duration: TimeInterval?
    var tags: [Tag]
    
    /// Standard initializer for an `Audio`
    /// - Parameters:
    ///   - firestoreID: The `FirestoreID` associated with this object in Firestore
    ///   - fileID: The `FileID` associated with this object's files in Firestore
    ///   - sourceURL: The `URL` that links to the source content
    ///   - title: The content title
    ///   - author: The `Rabbi` object credited with authoring this object
    ///   - description: The content description
    ///   - date: The time that this content was uploaded to the server
    ///   - duration: The duration of the content in seconds
    ///   - tags: `Tag` references to this object's topics
    init(id firestoreID: FirestoreID, fileID: FileID? = nil, sourceURL: URL, title: String, author: Rabbi, description: String, date: Date, duration: TimeInterval?, tags: [Tag]) {
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
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(firestoreID)
    }
    
    static func == (lhs: Audio, rhs: Audio) -> Bool {
        lhs.firestoreID == rhs.firestoreID
    }
}

/// An enhanced wrapper on a `Tag` which includes an icon
struct Category {
    var tag: Tag
    
    /// The `Image` associated with this `Tag`
    var icon: Image
}
