//
//  YTS.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 11/10/21.
//

import Foundation
import SwiftUI
import FirebaseDynamicLinks

typealias FirestoreID = String
typealias FileID = String

// MARK: - HomePageAlert
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

// MARK: - NewsArticle
class NewsArticle: Identifiable {
    var id: FirestoreID
    var images: [SlideshowImage]
    var title: String
    var body: String
    var uploaded: Date
    var author: String
    var isMostRecentArticle: Bool = false
    
    init(id: FirestoreID, title: String, body: String, uploaded: Date, author: String, images: [SlideshowImage] = []) {
        self.id = id
        self.title = title
        self.body = body
        self.uploaded = uploaded
        self.author = author
        self.images = images
    }
    
    static public var sample = NewsArticle(id: "",
                                           title: "Sample Article!!",
                                           body: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Morbi lacinia ultrices interdum. Praesent cursus nec erat cursus vehicula. Quisque ac ornare mauris. Duis vitae sem consequat, accumsan tellus eget, ullamcorper ipsum. Vivamus in euismod nisi, at lacinia mi. Etiam vitae euismod est. Morbi commodo suscipit urna sit amet iaculis.  Sed massa turpis, faucibus eu lectus vel, sollicitudin fermentum urna. Nunc vulputate efficitur sodales. Quisque ex neque, dignissim sit amet suscipit sed, dapibus id justo. Ut suscipit ut tellus eu accumsan. Aliquam vehicula egestas rutrum. Cras sagittis erat sed justo scelerisque consectetur vitae in urna. Phasellus magna lacus, tristique aliquam neque sit amet, porta varius neque. Sed quis felis feugiat, venenatis nulla et, tincidunt leo. Praesent ut purus quis mauris rutrum dignissim. Quisque libero risus, pharetra nec velit quis, ullamcorper mattis arcu. Pellentesque laoreet mi ac eleifend tempor. Fusce nunc eros, malesuada eu mi pulvinar, dictum dapibus eros. In hac habitasse platea dictumst. Integer non finibus tellus, at gravida augue.  Fusce convallis magna sem, ac bibendum diam ultrices et. Sed ac lectus ultricies, dapibus libero eget, mattis sapien. Aliquam erat volutpat. In nec ligula ut tellus tincidunt consequat nec sit amet nisl. Nam vitae ullamcorper neque. Nullam placerat pharetra mi, eget aliquam arcu pharetra in. Mauris et neque egestas mi scelerisque congue. Nulla id erat vitae quam convallis vehicula. Morbi commodo erat non tristique venenatis.  Aliquam magna quam, dapibus vel posuere non, pulvinar et mauris. Aenean enim tellus, viverra nec viverra quis, aliquet at tortor. Curabitur ligula lorem, ornare eget lectus quis, condimentum pellentesque purus. Vivamus dictum et metus eu vestibulum. Duis a nibh pulvinar felis lobortis ornare. Sed leo purus, eleifend id placerat ac, pulvinar sit amet metus. Nulla vitae ex ut leo egestas venenatis vestibulum vitae dui.  Suspendisse imperdiet velit mattis nunc facilisis, in tristique arcu suscipit. Vestibulum tristique ligula est, vitae sodales lacus accumsan sit amet. Pellentesque sollicitudin dignissim felis, eget lacinia dolor hendrerit et. Donec vel felis ante. Donec faucibus dui nunc, sit amet efficitur libero consequat id. Fusce arcu mi, pharetra sit amet efficitur semper, blandit quis eros. Nunc purus enim, consequat vitae facilisis eget, tincidunt quis sem. Fusce porttitor viverra velit, vel luctus tortor euismod eu.",
                                           uploaded: Date(timeIntervalSince1970: 1642351054),
                                           author: "Benji Tusk")
}


// MARK: - Rabbi
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

// MARK: - DetailedRabbi
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
    
    /// Standard initalizer used when `URL` for a profile image is available and an `Image` is not
    /// - Parameters:
    ///   - firestoreID: The `FirestoreID` associated with this object in Firestore
    ///   - name: The name associated with this object
    ///   - profileImageURL: The `URL` that links to this object's profile image
    init(id firestoreID: FirestoreID, name: String, profileImageURL: URL) {
        super.init(id: firestoreID, name: name)
        self.profileImageURL = profileImageURL
    }
    
    static public var sample: DetailedRabbi =
        DetailedRabbi(id: "TEST_ID", name: "Test Uploader", profileImageURL: URL(string: "https://firebasestorage.googleapis.com/v0/b/yeshivat-torat-shraga.appspot.com/o/profile-pictures%2Frabbieichler.jpeg?alt=media&token=8f1e24d1-0531-47cf-9a9e-726a613cd3dd")!)
    
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


// MARK: - YTSContent
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
    var tag: Tag { get }
    
    var name: String { get }
    
//    var favoritedAt: Date? { get set }
    
    //    func toggleFavorites() -> Error?
    
    var storedShareURL: URL? { get set }
    
    mutating func shareURL(completion: ((_ shareURL: URL?) -> Void)?)
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

// MARK: - Video
class Video: YTSContent, URLImageable {
    internal var firestoreID: FirestoreID
    internal var fileID: FileID?
    var sourceURL: URL?
    var title: String
    var author: Rabbi
    var description: String
    var date: Date
    var duration: TimeInterval?
    var tag: Tag
    var thumbnail: Image?
    var thumbnailURL: URL?
//    var favoritedAt: Date?
    
    internal var storedShareURL: URL?
    
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
    ///   - tag: `Tag` reference to this object's topics
    ///   - thumbnail: The thumbnail associated with this content
    init(id firestoreID: FirestoreID, fileID: FileID? = nil, sourceURL: URL, title: String, author: Rabbi, description: String, date: Date, duration: TimeInterval?, tag: Tag, thumbnail: Image) {
        self.firestoreID = firestoreID
        self.fileID = fileID
        self.sourceURL = sourceURL
        self.title = title
        self.author = author
        self.description = description
        self.date = date
        self.duration = duration
        self.tag = tag
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
    ///   - tag: `Tag` reference to this object's topics
    ///   - thumbnailURL: The `URL` associated with this content's thumbnail image
    init(id firestoreID: FirestoreID, fileID: FileID? = nil, sourceURL: URL, title: String, author: Rabbi, description: String, date: Date, duration: TimeInterval?, tag: Tag, thumbnailURL: URL) {
        self.firestoreID = firestoreID
        self.fileID = fileID
        self.sourceURL = sourceURL
        self.title = title
        self.author = author
        self.description = description
        self.date = date
        self.duration = duration
        self.tag = tag
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
    ///   - tag: `Tag` reference to this object's topics
    init(id firestoreID: FirestoreID, fileID: FileID? = nil, sourceURL: URL, title: String, author: Rabbi, description: String, date: Date, duration: TimeInterval?, tag: Tag) {
        self.firestoreID = firestoreID
        self.fileID = fileID
        self.sourceURL = sourceURL
        self.title = title
        self.author = author
        self.description = description
        self.date = date
        self.duration = duration
        self.tag = tag
    }
    
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(firestoreID)
    }
    
    static func == (lhs: Video, rhs: Video) -> Bool {
        lhs.firestoreID == rhs.firestoreID
    }
    
    func shareURL(completion: ((_ shareURL: URL?) -> Void)? = nil) {
        if let shareURL = storedShareURL {
            completion?(shareURL)
        } else {
            var components = URLComponents()
            components.scheme = "https"
            components.host = "app.toratshraga.com"
            components.path = "/content"
            
            let itemIDQueryItem = URLQueryItem(name: "id", value: firestoreID)
            components.queryItems = [itemIDQueryItem]
            
            guard let linkParameter = components.url else {
                self.storedShareURL = nil
                completion?(nil)
                return
            }
            
            let domain = "https://app.toratshraga.com/content"
            
            guard let linkBuilder = DynamicLinkComponents(link: linkParameter, domainURIPrefix: domain) else {
                self.storedShareURL = nil
                completion?(nil)
                return
            }
            
            guard let myBundleId = Bundle.main.bundleIdentifier else {
                self.storedShareURL = nil
                completion?(nil)
                return
            }
            
            linkBuilder.navigationInfoParameters = DynamicLinkNavigationInfoParameters()
            linkBuilder.navigationInfoParameters?.isForcedRedirectEnabled = true

            linkBuilder.iOSParameters?.appStoreID = "1598556472"
            linkBuilder.iOSParameters = DynamicLinkIOSParameters(bundleID: myBundleId)
            
            linkBuilder.socialMetaTagParameters = DynamicLinkSocialMetaTagParameters()
            linkBuilder.socialMetaTagParameters?.title = title
            linkBuilder.socialMetaTagParameters?.descriptionText = author.name
            linkBuilder.socialMetaTagParameters?.imageURL = URL(string: "http://toratshraga.com/wp-content/uploads/2016/11/cropped-torat.jpg")!
            
            linkBuilder.iOSParameters = DynamicLinkIOSParameters(bundleID: "com.reesedevelopment.YTS")
            //            linkBuilder.androidParameters = DynamicLinkAndroidParameters(packageName: "com.example.android")
            
//            guard let longDynamicLink = linkBuilder.url else {
//                self.storedShareURL = nil
//                completion(nil)
//                return
//            }
            
            linkBuilder.shorten { (url, warnings, error) in
                if let error = error {
                    print("Error getting shortened URL: \(error)")
                    self.storedShareURL = nil
                    completion?(nil)
                    return
                  }
                
                  if let warnings = warnings {
                    for warning in warnings {
                      print("Warning: \(warning)")
                    }
                  }
                
                  guard let url = url else {
                      self.storedShareURL = nil
                      completion?(nil)
                      return
                  }
                
                self.storedShareURL = url
                completion?(url)
                return
            }
        }
    }
    
    static let sample = Video(id: "TEST_ID",
                              fileID: "testvideo",
                              sourceURL: URL(string: "https://storage.googleapis.com/yeshivat-torat-shraga.appspot.com/HLSStreams/video/SSStest.mp4/test.mp4.m3u8")!,
                              title: "Test Video",
                              author: DetailedRabbi.sample,
                              description: "Testing Video",
                              date: .distantPast,
                              duration: 100,
                              tag: .sample,
                              thumbnailURL: URL(string: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSFcgVculbjt02kuQlNQW0ybihHYvUA7invbw&usqp=CAU")!)
}

// MARK: - Audio
class Audio: YTSContent, Hashable, ObservableObject {
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
    var tag: Tag
    
    var storedShareURL: URL?
    
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
    init(id firestoreID: FirestoreID, fileID: FileID? = nil, sourceURL: URL, title: String, author: Rabbi, description: String, date: Date, duration: TimeInterval?, tag: Tag) {
        self.firestoreID = firestoreID
        self.fileID = fileID
        self.sourceURL = sourceURL
        self.title = title
        self.author = author
        self.description = description
        self.date = date
        self.duration = duration
        self.tag = tag
    }
        
    func hash(into hasher: inout Hasher) {
        hasher.combine(firestoreID)
    }
    
    func shareURL(completion: ((_ shareURL: URL?) -> Void)? = nil) {
        if let shareURL = storedShareURL {
            completion?(shareURL)
        } else {
            var components = URLComponents()
            components.scheme = "https"
            components.host = "app.toratshraga.com"
            components.path = "/content"
            
            let itemIDQueryItem = URLQueryItem(name: "id", value: firestoreID)
            components.queryItems = [itemIDQueryItem]
            
            guard let linkParameter = components.url else {
                self.storedShareURL = nil
                completion?(nil)
                return
            }
            
            let domain = "https://app.toratshraga.com/content"
            
            guard let linkBuilder = DynamicLinkComponents(link: linkParameter, domainURIPrefix: domain) else {
                self.storedShareURL = nil
                completion?(nil)
                return
            }
            
            guard let myBundleId = Bundle.main.bundleIdentifier else {
                self.storedShareURL = nil
                completion?(nil)
                return
            }
            
            linkBuilder.navigationInfoParameters = DynamicLinkNavigationInfoParameters()
            linkBuilder.navigationInfoParameters?.isForcedRedirectEnabled = true
            linkBuilder.iOSParameters = DynamicLinkIOSParameters(bundleID: myBundleId)
            linkBuilder.iOSParameters?.appStoreID = "1598556472"
            
            linkBuilder.socialMetaTagParameters = DynamicLinkSocialMetaTagParameters()
            linkBuilder.socialMetaTagParameters?.title = title
            linkBuilder.socialMetaTagParameters?.descriptionText = author.name
            linkBuilder.socialMetaTagParameters?.imageURL = URL(string: "http://toratshraga.com/wp-content/uploads/2016/11/cropped-torat.jpg")!
            
            //            linkBuilder.androidParameters = DynamicLinkAndroidParameters(packageName: "com.example.android")
            
//            guard let longDynamicLink = linkBuilder.url else {
//                self.storedShareURL = nil
//                completion(nil)
//                return
//            }
            
            linkBuilder.shorten { (url, warnings, error) in
                if let error = error {
                    print("Error getting shortened URL: \(error)")
                    self.storedShareURL = nil
                    completion?(nil)
                    return
                  }
                
                  if let warnings = warnings {
                    for warning in warnings {
                      print("Warning: \(warning)")
                    }
                  }
                
                  guard let url = url else {
                      self.storedShareURL = nil
                      completion?(nil)
                      return
                  }
                
                print("Generated deep link: \(url)")
                
                self.storedShareURL = url
                completion?(url)
                return
            }
        }
    }
        
    static func == (lhs: Audio, rhs: Audio) -> Bool {
        lhs.firestoreID == rhs.firestoreID
    }
    
    static let sample = Audio(
        id: "TEST_ID",
        fileID: "RabbiDavid",
        sourceURL: URL(string: "https://firebasestorage.googleapis.com/v0/b/kol-hatorah-kulah.appspot.com/o/content%2FFFF1636709091A637.mp4?alt=media&token=2e9e1526-56f8-404d-8107-c90d69c7a760")!,
        title: "really really really long sample title that should force the card to expand horizontally",
        author: DetailedRabbi(
            id: "wEDCQ71W0bVEUtTM1x5Z",
            name: "Rabbi Ifrah", profileImageURL: URL(string: "https://firebasestorage.googleapis.com/v0/b/yeshivat-torat-shraga.appspot.com/o/profile-pictures%2FD3_0069-e1604486300557-174x174.jpg?alt=media&token=bc0b78bb-f354-464d-8d78-9dae1693093d")!),
        description: "Test description",
        date: .distantPast,
        duration: 2609,
        tag: .sample)
}

// MARK: - Tag
class Tag: ObservableObject, Hashable {
    typealias Metadata = (newLastLoadedDocumentID: FirestoreID?, finalCall: Bool, isLoadingContent: Bool)
    var id: FirestoreID
    var name: String
    var children: [Tag]?
    var isParent: Bool
    @Published var metadata: Metadata
    
    init(_ name: String, id: FirestoreID, isParent: Bool = false, children: [Tag]? = nil) {
        self.name = name
        self.id = id
        self.isParent = isParent
        self.children = children
        self.metadata = (newLastLoadedDocumentID: nil, finalCall: false, isLoadingContent: true)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Tag, rhs: Tag) -> Bool {
        lhs.id == rhs.id
    }
    
    static var sample = Tag("Chagim", id: "TEST_ID")
}

// MARK: - Category
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
    
    init(name: String, id: FirestoreID, isParent: Bool = false, icon: Image, children: [Tag]? = nil) {
        self.icon = icon
        super.init(name, id: id, isParent: isParent, children: children)
    }
}

typealias AVContent = (videos: [Video], audios: [Audio])

// MARK: - SortableYTSContent
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
