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
    private(set) var firestoreID: FirestoreID
    
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
        DetailedRabbi(id: "wEDCQ71W0bVEUtTM1x5Z", name: "Rabbi David", profileImage: Image("SampleRabbi")),
        DetailedRabbi(id: "8h33fFYYSIn5V4crue8f", name: "Test Uploader", profileImageURL: URL(string: "https://storage.googleapis.com/yeshivat-torat-shraga.appspot.com/profile-pictures/test.png")!),
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

protocol Tileable: URLImageable, Hashable {
    var name: String { get }
}

/// A content object modeled like a Firestore content document
protocol YTSContent: Tileable {
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

extension YTSContent {
    var sortable: SortableYTSContent {
        if let content = self as? Video {
            return SortableYTSContent(video: content)
        } else if let content = self as? Audio {
            return SortableYTSContent(audio: content)
        }
        fatalError("Not able to handle content that is not Video nor Audio. (G01F)")
    }
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
    
    var name: String {
        return title
    }
    var image: Image? {
        get {
            return thumbnail
        }
        set {
            thumbnail = newValue
        }
    }
    var imageURL: URL? {
        return thumbnailURL
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
    
    static let sample = Video(id: "7g5JY4X1bYURqv8votbB",
                              fileID: "testvideo",
                              sourceURL: URL(string: "https://storage.googleapis.com/yeshivat-torat-shraga.appspot.com/HLSStreams/video/SSStest.mp4/test.mp4.m3u8")!,
                              title: "Test Video",
                              author: Rabbi(
                                id: "8h33fFYYSIn5V4crue8f",
                                name: "Test Uploader"),
                              description: "Testing Video",
                              date: .distantPast,
                              duration: 100,
                              tags: [],
                              thumbnailURL: URL(string: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSFcgVculbjt02kuQlNQW0ybihHYvUA7invbw&usqp=CAU")!)
}

class Audio: YTSContent, Hashable {
    var name: String
    
    var image: Image?
    
    var imageURL: URL?
    
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
        self.name = title
        
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(firestoreID)
    }
    
    static func == (lhs: Audio, rhs: Audio) -> Bool {
        lhs.firestoreID == rhs.firestoreID
    }
    
    static let sample = Audio(
        id: "PD9DX0Hf8v1dJPmGMk97",
        fileID: "RabbiDavid",
        sourceURL: URL(string: "https://firebasestorage.googleapis.com/v0/b/kol-hatorah-kulah.appspot.com/o/content%2FFFF1636709091A637.mp4?alt=media&token=2e9e1526-56f8-404d-8107-c90d69c7a760")!,
        title: "Hilchot Har Habayit",
        author: Rabbi(
            id: "wEDCQ71W0bVEUtTM1x5Z",
            name: "Rabbi David"),
        description: "Test description",
        date: .distantPast,
        duration: 100,
        tags: [])
}

class Tag: Hashable {
    var name: String
    
    init(_ name: String) {
        self.name = name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    static func == (lhs: Tag, rhs: Tag) -> Bool {
        lhs.name == rhs.name
    }
}

/// An enhanced wrapper on a ``Tag`` which includes an icon
class Category: Tag {
    /// The icon associated with the ``Tag``
    var icon: Image
    
    init(name: String, icon: Image) {
        self.icon = icon
        super.init(name)
    }
}

typealias Content = (videos: [Video], audios: [Audio])

struct SortableYTSContent: Hashable {
    var video: Video?
    var audio: Audio?
    var date: Date? {
        if let video = self.video {
            return video.date
        } else if let audio = self.audio {
            return audio.date
        }
        fatalError("""
Unable to get date of non video or audio object.
Theoretically, this error should be impossible to reach,
So if you are seeing this, something is seriously wrong...
G02F
""")
    }
    
    init(video: Video) {
        self.video = video
    }
    init(audio: Audio) {
        self.audio = audio
    }
}
