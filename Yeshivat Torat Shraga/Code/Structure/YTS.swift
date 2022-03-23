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


class HomePageAlert {
    // title should have 40 char limit
    var title: String
    var body: String
    var id: String
    
    init(id: String, title: String, body: String) {
        self.title = title
        self.body = body
        self.id = id
    }
    
}

class NewsArticle: Identifiable {
    var images: [SlideshowImage]
    var title: String
    var body: String
    var uploaded: Date
    var author: String
    
    init(title: String, body: String, uploaded: Date, author: String, images: [SlideshowImage] = []) {
        self.title = title
        self.body = body
        self.uploaded = uploaded
        self.author = author
        self.images = images
    }
    
    static public var sample = NewsArticle(title: "Sample Article!!",
                                           body: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Morbi lacinia ultrices interdum. Praesent cursus nec erat cursus vehicula. Quisque ac ornare mauris. Duis vitae sem consequat, accumsan tellus eget, ullamcorper ipsum. Vivamus in euismod nisi, at lacinia mi. Etiam vitae euismod est. Morbi commodo suscipit urna sit amet iaculis.  Sed massa turpis, faucibus eu lectus vel, sollicitudin fermentum urna. Nunc vulputate efficitur sodales. Quisque ex neque, dignissim sit amet suscipit sed, dapibus id justo. Ut suscipit ut tellus eu accumsan. Aliquam vehicula egestas rutrum. Cras sagittis erat sed justo scelerisque consectetur vitae in urna. Phasellus magna lacus, tristique aliquam neque sit amet, porta varius neque. Sed quis felis feugiat, venenatis nulla et, tincidunt leo. Praesent ut purus quis mauris rutrum dignissim. Quisque libero risus, pharetra nec velit quis, ullamcorper mattis arcu. Pellentesque laoreet mi ac eleifend tempor. Fusce nunc eros, malesuada eu mi pulvinar, dictum dapibus eros. In hac habitasse platea dictumst. Integer non finibus tellus, at gravida augue.  Fusce convallis magna sem, ac bibendum diam ultrices et. Sed ac lectus ultricies, dapibus libero eget, mattis sapien. Aliquam erat volutpat. In nec ligula ut tellus tincidunt consequat nec sit amet nisl. Nam vitae ullamcorper neque. Nullam placerat pharetra mi, eget aliquam arcu pharetra in. Mauris et neque egestas mi scelerisque congue. Nulla id erat vitae quam convallis vehicula. Morbi commodo erat non tristique venenatis.  Aliquam magna quam, dapibus vel posuere non, pulvinar et mauris. Aenean enim tellus, viverra nec viverra quis, aliquet at tortor. Curabitur ligula lorem, ornare eget lectus quis, condimentum pellentesque purus. Vivamus dictum et metus eu vestibulum. Duis a nibh pulvinar felis lobortis ornare. Sed leo purus, eleifend id placerat ac, pulvinar sit amet metus. Nulla vitae ex ut leo egestas venenatis vestibulum vitae dui.  Suspendisse imperdiet velit mattis nunc facilisis, in tristique arcu suscipit. Vestibulum tristique ligula est, vitae sodales lacus accumsan sit amet. Pellentesque sollicitudin dignissim felis, eget lacinia dolor hendrerit et. Donec vel felis ante. Donec faucibus dui nunc, sit amet efficitur libero consequat id. Fusce arcu mi, pharetra sit amet efficitur semper, blandit quis eros. Nunc purus enim, consequat vitae facilisis eget, tincidunt quis sem. Fusce porttitor viverra velit, vel luctus tortor euismod eu.",
                                           uploaded: Date(timeIntervalSince1970: 1642351054),
                                           author: "Benji Tusk")
}



class Rabbi: Hashable {
    /// The `FirestoreID` associated with this object in Firestore
    private(set) var firestoreID: FirestoreID
    
    /// The name associated with this object
    var name: String
    var isFavorite: Bool
    
    init(id firestoreID: FirestoreID, name: String, isFavorite: Bool = false) {
        self.firestoreID = firestoreID
        self.name = name
        self.isFavorite = isFavorite
    }
    
    convenience init?(cdPerson: CDPerson, isFavorite: Bool = false) {
        guard let firestoreID = cdPerson.firestoreID, let name = cdPerson.name else {
            return nil
        }
        
        self.init(id: firestoreID, name: name, isFavorite: isFavorite)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(firestoreID)
    }
    
    static func == (lhs: Rabbi, rhs: Rabbi) -> Bool {
        lhs.firestoreID == rhs.firestoreID
    }
}

class DetailedRabbi: Rabbi, URLImageable {
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
    init(id firestoreID: FirestoreID, name: String, profileImage: Image, isFavorite: Bool = false) {
        super.init(id: firestoreID, name: name, isFavorite: isFavorite)
        self.profileImage = profileImage
    }
    
    /// Standard initalizer used when `URL` for a profile image is available and an `Image` is not
    /// - Parameters:
    ///   - firestoreID: The `FirestoreID` associated with this object in Firestore
    ///   - name: The name associated with this object
    ///   - profileImageURL: The `URL` that links to this object's profile image
    init(id firestoreID: FirestoreID, name: String, profileImageURL: URL, isFavorite: Bool = false) {
        super.init(id: firestoreID, name: name, isFavorite: isFavorite)
        self.profileImageURL = profileImageURL
    }
    
    init?(cdPerson: CDPerson, isFavorite: Bool = false) {
        guard let firestoreID = cdPerson.firestoreID, let name = cdPerson.name, let profileImageData = cdPerson.profileImageData else {
            return nil
        }
        
        guard let profileUIImage = UIImage(data: profileImageData) else {
            return nil
        }
        
        self.profileImage = Image(uiImage: profileUIImage)
        super.init(id: firestoreID, name: name, isFavorite: isFavorite)
    }
    
    func toggleFavorites() -> Error? {
        var error: Error? = nil
        self.isFavorite.toggle()
        if self.isFavorite {
            Favorites.shared.save(self) { favorites, err in
                if err != nil {
                    Haptics.shared.notify(.error)
                    error = err
                } else {
                    Haptics.shared.notify(.success)
                }
            }
        } else {
            Favorites.shared.delete(self) { favorites, err in
                if err != nil {
                    Haptics.shared.notify(.error)
                    error = err
                } else {
                    Haptics.shared.notify(.warning)
                }
            }
        }
        return error
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


/// A content object modeled like a Firestore content document
protocol YTSContent: URLImageable, Hashable {
    /// The `FirestoreID` associated with this object in Firestore
    var firestoreID: FirestoreID { get }
    
    /// The `FileID` associated with this object's files in Firestore
    var fileID: FileID? { get }
    
    /// The `URL` that links to the source content
    var sourceURL: URL? { get }
    
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
    
    var name: String { get }
    
//    var favoritedAt: Date? { get set }
    
//    func toggleFavorites() -> Error?
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

class Video: YTSContent, URLImageable {
    internal var firestoreID: FirestoreID
    internal var fileID: FileID?
    var sourceURL: URL?
    var title: String
    var author: Rabbi
    var description: String
    var date: Date
    var duration: TimeInterval?
    var tags: [Tag]
    var thumbnail: Image?
    var thumbnailURL: URL?
//    var favoritedAt: Date?
    
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
    init(id firestoreID: FirestoreID, fileID: FileID? = nil, sourceURL: URL, title: String, author: Rabbi, description: String, date: Date, duration: TimeInterval?, tags: [Tag], thumbnail: Image, favoritedAt: Date? = nil) {
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
//        self.favoritedAt = favoritedAt
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
    init(id firestoreID: FirestoreID, fileID: FileID? = nil, sourceURL: URL, title: String, author: Rabbi, description: String, date: Date, duration: TimeInterval?, tags: [Tag], thumbnailURL: URL, favoritedAt: Date? = nil) {
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
//        self.favoritedAt = favoritedAt
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
    
    init?(cdVideo: CDVideo) {
        guard let firestoreID = cdVideo.firestoreID, let fileID = cdVideo.fileID, let title = cdVideo.title, let description = cdVideo.body, let uploadDate = cdVideo.uploadDate, let author = cdVideo.author, let thumbnailData = cdVideo.thumbnailData else {
            return nil
        }
        
        guard let thumbnailUIImage = UIImage(data: thumbnailData) else {
            return nil
        }
        
        self.thumbnail = Image(uiImage: thumbnailUIImage)
//        self.favoritedAt = cdVideo.favoritedAt
        
        if let author = DetailedRabbi(cdPerson: author) {
            self.author = author
        } else if let author = Rabbi(cdPerson: author) {
            self.author = author
        } else {
            return nil
        }
        
        self.firestoreID = firestoreID
        self.fileID = fileID
        self.title = title
        self.description = description
//            MARK: TAGS HARD-PASSED IN
        self.tags = []
        self.date = uploadDate
        self.duration = TimeInterval(cdVideo.duration)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(firestoreID)
    }
    
    static func == (lhs: Video, rhs: Video) -> Bool {
        lhs.firestoreID == rhs.firestoreID
    }
    
//    func toggleFavorites() -> Error? {
//        var error: Error? = nil
//        if self.favoritedAt == nil {
//            self.favoritedAt = Date()
//            Favorites.shared.save(self) { favorites, err in
//                if err != nil {
//                    Haptics.shared.notify(.error)
//                    error = err
//                } else {
//                    print("Video saved to CoreData successfuly")
//                    Haptics.shared.notify(.success)
//                }
//            }
//        } else {
//            self.favoritedAt = nil
//            Favorites.shared.delete(self) { favorites, err in
//                if err != nil {
//                    Haptics.shared.notify(.error)
//                    error = err
//                } else {
//                    Haptics.shared.notify(.warning)
//                }
//            }
//        }
//        return error
//    }
    
    static let sample = Video(id: "7g5JY4X1bYURqv8votbB",
                              fileID: "testvideo",
                              sourceURL: URL(string: "https://storage.googleapis.com/yeshivat-torat-shraga.appspot.com/HLSStreams/video/SSStest.mp4/test.mp4.m3u8")!,
                              title: "Test Video",
                              author: DetailedRabbi.samples[2],
                              description: "Testing Video",
                              date: .distantPast,
                              duration: 100,
                              tags: [],
                              thumbnailURL: URL(string: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSFcgVculbjt02kuQlNQW0ybihHYvUA7invbw&usqp=CAU")!,
                              favoritedAt: nil)
}

class Audio: YTSContent, Hashable {
    var image: Image? = Image("AudioPlaceholder")
    var imageURL: URL?
    
    internal var firestoreID: FirestoreID
    internal var fileID: FileID?
    var sourceURL: URL?
    var title: String
    var author: Rabbi
    var description: String
    var date: Date
    var duration: TimeInterval?
    var tags: [Tag]
//    var favoritedAt: Date?
    var name: String {
        return title
    }
    
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
    init(id firestoreID: FirestoreID, fileID: FileID? = nil, sourceURL: URL, title: String, author: Rabbi, description: String, date: Date, duration: TimeInterval?, tags: [Tag], favoritedAt: Date? = nil) {
        self.firestoreID = firestoreID
        self.fileID = fileID
        self.sourceURL = sourceURL
        self.title = title
        self.author = author
        self.description = description
        self.date = date
        self.duration = duration
        self.tags = tags
//        self.favoritedAt = favoritedAt
    }
    
    init?(cdAudio: CDAudio) {
        guard let firestoreID = cdAudio.firestoreID, let fileID = cdAudio.fileID, let title = cdAudio.title, let description = cdAudio.body, let uploadDate = cdAudio.uploadDate, let author = cdAudio.author else {
            return nil
        }
        
        if let author = DetailedRabbi(cdPerson: author) {
            self.author = author
        } else if let author = Rabbi(cdPerson: author) {
            self.author = author
        } else {
            return nil
        }
        
        self.firestoreID = firestoreID
        self.fileID = fileID
        self.title = title
        self.description = description
//        self.favoritedAt = cdAudio.favoritedAt
//            MARK: TAGS HARD-PASSED IN
        self.tags = []
        self.date = uploadDate
        self.duration = TimeInterval(cdAudio.duration)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(firestoreID)
    }
    
//    func toggleFavorites(completion: ((_ favorites: FavoritesTuple?, _ error: Error?) -> Void) -> Error? {
//        var error: Error? = nil
//        
//        if self.favoritedAt == nil {
//            self.favoritedAt = Date()
//            Favorites.shared.save(self) { favorites, err in
//                completion(favorites, err)
//                if err != nil {
//                    Haptics.shared.notify(.error)
//                    error = err
//                } else {
//                    print("Audio saved to CoreData Successfuly")
//                    Haptics.shared.notify(.success)
//                }
//            }
//        } else {
//            self.favoritedAt = nil
//            Favorites.shared.delete(self) { favorites, err in
//                if err != nil {
//                    Haptics.shared.notify(.error)
//                    error = err
//                } else {
//                    Haptics.shared.notify(.warning)
//                }
//            }
//        }
//        completion()
//        return error
//    }
    
    static func == (lhs: Audio, rhs: Audio) -> Bool {
        lhs.firestoreID == rhs.firestoreID
    }
    
    static let sample = Audio(
        id: "PD9DX0Hf8v1dJPmGMk97",
        fileID: "RabbiDavid",
        sourceURL: URL(string: "https://firebasestorage.googleapis.com/v0/b/kol-hatorah-kulah.appspot.com/o/content%2FFFF1636709091A637.mp4?alt=media&token=2e9e1526-56f8-404d-8107-c90d69c7a760")!,
        title: "Hilchot Har Habayit",
        author: DetailedRabbi(
            id: "wEDCQ71W0bVEUtTM1x5Z",
            name: "Rabbi David", profileImageURL: URL(string: "https://firebasestorage.googleapis.com/v0/b/yeshivat-torat-shraga.appspot.com/o/profile-pictures%2Fadavid_lp-2.jpg?alt=media&token=0debf11a-d4ef-4aa8-b224-ba6420e1d246")!),
        description: "Test description",
        date: .distantPast,
        duration: 2609,
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
    
    static var sample = Tag("Parsha")
}

/// An enhanced wrapper on a ``Tag`` which includes an icon
class Category: Tag, URLImageable {
    
    /// The icon associated with the ``Tag``
    var icon: Image
    
    internal var image: Image? {
        get {
            return icon
        }
        set {}
    }
    
    var imageURL: URL? {
        return nil
    }
    
    init(name: String, icon: Image) {
        self.icon = icon
        super.init(name)
    }
}

let tags: [Tag] = [Category(name: "Parsha", icon: Image("parsha")), Category(name: "Chanuka", icon: Image("chanuka")), Tag("Mussar"), Tag("Purim")]

typealias AVContent = (videos: [Video], audios: [Audio])

class SortableYTSContent: Hashable {
    static func == (lhs: SortableYTSContent, rhs: SortableYTSContent) -> Bool {
        return lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        let id = self.video?.firestoreID ?? self.audio!.firestoreID
        hasher.combine(id)
    }

    let id = UUID()
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
(F01F)
""")
    }
    
    init(video: Video) {
        self.video = video
    }
    init(audio: Audio) {
        self.audio = audio
    }
}
