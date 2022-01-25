//
//  Favorites.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 1/6/22.
//

import Foundation
import UIKit
import SwiftUI

class Favorites {
    static let delegate = (UIApplication.shared.delegate as! AppDelegate)
    typealias FavoritesTuple = (videos: [Video]?, audios: [Audio]?, people: [DetailedRabbi]?)
    
    static func save(_ rabbiToSave: DetailedRabbi, completion: ((_ favorites: FavoritesTuple?, _ error: Error?) -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            let group = DispatchGroup()
            
            group.enter()
            var profilePictureData: Data?
            
            let profilePicture = rabbiToSave.profileImage
            let profilePictureURL = rabbiToSave.profileImageURL
            
            if let profilePicture = profilePicture {
                DispatchQueue.main.async {
                    guard let data = authorProfilePicture.asUIImage().jpegData(compressionQuality: 1.0) else {
                        DispatchQueue.main.async {
                            loadFavorites(completion: completion)
                        }
                        return
                    }
                    profilePictureData = data
                    group.leave()
                }
            } else if let profilePictureURL = profilePictureURL {
                guard let data = try? Data(contentsOf: authorProfilePictureURL) else {
                    DispatchQueue.main.async {
                        loadFavorites(completion: completion)
                    }
                    return
                }
                profilePictureData = data
                group.leave()
            } else {
                group.leave()
            }
            
            let managedContext = delegate.persistentContainer.viewContext
            
            var cdAuthor: CDPerson
            cdAuthor = CDPerson(context: managedContext)
            
            cdAuthor.firestoreID = rabbiToSave.firestoreID
            cdAuthor.name = rabbiToSave.name
            cdAuthor.owned = false
            
            group.notify(queue: .main) {
                cdAuthor.profileImageData = profilePictureData
                
                
                    DispatchQueue.main.async {
                do {
                        try managedContext.save()
                        loadFavorites(completion: completion)
                } catch let error as NSError {
                    print("Could not save. \(error), \(error.userInfo)")
                        loadFavorites(completion: completion)
                }
                    }
            }
        }
    }
    
    static func save(_ videoToSave: Video, completion: ((_ favorites: FavoritesTuple?, _ error: Error?) -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            let group = DispatchGroup()
            
            group.enter()
            var authorProfilePictureData: Data?
            
            let authorProfilePicture = (videoToSave.author as? DetailedRabbi)?.profileImage
            let authorProfilePictureURL = (videoToSave.author as? DetailedRabbi)?.profileImageURL
            
            if let authorProfilePicture = authorProfilePicture {
                DispatchQueue.main.async {
                    guard let data = authorProfilePicture.asUIImage().jpegData(compressionQuality: 1.0) else {
                        DispatchQueue.main.async {
                            loadFavorites(completion: completion)
                        }
                        return
                    }
                    authorProfilePictureData = data
                    group.leave()
                }
            } else if let authorProfilePictureURL = authorProfilePictureURL {
                guard let data = try? Data(contentsOf: authorProfilePictureURL) else {
                    DispatchQueue.main.async {
                        loadFavorites(completion: completion)
                    }
                    return
                }
                authorProfilePictureData = data
                group.leave()
            } else {
                group.leave()
            }
            
            group.enter()
            var thumbnailData: Data?
            
            let thumbnail = videoToSave.thumbnail
            let thumbnailURL = videoToSave.thumbnailURL
            
            if let thumbnail = thumbnail {
                DispatchQueue.main.async {
                    guard let data = thumbnail.asUIImage().jpegData(compressionQuality: 1.0) else {
                        DispatchQueue.main.async {
                            loadFavorites(completion: completion)
                        }
                        return
                    }
                    thumbnailData = data
                    group.leave()
                }
            } else if let thumbnailURL = thumbnailURL {
                guard let data = try? Data(contentsOf: thumbnailURL) else {
                    DispatchQueue.main.async {
                        loadFavorites(completion: completion)
                    }
                    return
                }
                thumbnailData = data
                group.leave()
            } else {
                group.leave()
            }
            
            
            guard let duration = videoToSave.duration else {
                DispatchQueue.main.async {
                    loadFavorites(completion: completion)
                }
                return
            }
            
            let managedContext = delegate.persistentContainer.viewContext
            
            let entity = CDVideo.entity()
            
            let cdVideo = CDVideo(entity: entity,
                                  insertInto: managedContext)
            
            cdVideo.firestoreID = videoToSave.firestoreID
            cdVideo.fileID = videoToSave.fileID
            cdVideo.title = videoToSave.title
            cdVideo.body = videoToSave.description
//            MARK: NOT SAVING TAGS
//            cdAudio.tags = audioToSave.tags
            cdVideo.uploadDate = videoToSave.date
            cdVideo.duration = Int64(duration)
            
            
            var cdAuthor: CDPerson
            cdAuthor = CDPerson(context: managedContext)
            
            cdAuthor.firestoreID = videoToSave.author.firestoreID
            cdAuthor.name = videoToSave.author.name
            cdAuthor.owned = true
            
            cdVideo.author = cdAuthor
            
            group.notify(queue: .main) {
                cdAuthor.profileImageData = authorProfilePictureData
                cdVideo.thumbnailData = thumbnailData
                
                
                    DispatchQueue.main.async {
                do {
                        try managedContext.save()
                        loadFavorites(completion: completion)
                } catch let error as NSError {
                    print("Could not save. \(error), \(error.userInfo)")
                        loadFavorites(completion: completion)
                }
                    }
            }
        }
    }
    
    static func save(_ audioToSave: Audio, completion: ((_ favorites: FavoritesTuple?, _ error: Error?) -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            let group = DispatchGroup()
            
            group.enter()
            var authorProfilePictureData: Data?
            
            let authorProfilePicture = (audioToSave.author as? DetailedRabbi)?.profileImage
            let authorProfilePictureURL = (audioToSave.author as? DetailedRabbi)?.profileImageURL
            
            if let authorProfilePicture = authorProfilePicture {
                DispatchQueue.main.async {
                    guard let data = authorProfilePicture.asUIImage().jpegData(compressionQuality: 1.0) else {
                        DispatchQueue.main.async {
                            loadFavorites(completion: completion)
                        }
                        return
                    }
                    authorProfilePictureData = data
                    group.leave()
                }
            } else if let authorProfilePictureURL = authorProfilePictureURL {
                guard let data = try? Data(contentsOf: authorProfilePictureURL) else {
                    DispatchQueue.main.async {
                        loadFavorites(completion: completion)
                    }
                    return
                }
                authorProfilePictureData = data
                group.leave()
            } else {
                group.leave()
            }
            
            guard let duration = audioToSave.duration else {
                DispatchQueue.main.async {
                    loadFavorites(completion: completion)
                }
                return
            }
            
            let managedContext = delegate.persistentContainer.viewContext
            
            let entity = CDAudio.entity()
            
            let cdAudio = CDAudio(entity: entity,
                                  insertInto: managedContext)
            
            cdAudio.firestoreID = audioToSave.firestoreID
            cdAudio.fileID = audioToSave.fileID
            cdAudio.title = audioToSave.title
            cdAudio.body = audioToSave.description
//            MARK: NOT SAVING TAGS
//            cdAudio.tags = audioToSave.tags
            cdAudio.uploadDate = audioToSave.date
            cdAudio.duration = Int64(duration)
            
            
            var cdAuthor: CDPerson
            cdAuthor = CDPerson(context: managedContext)
            
            cdAuthor.firestoreID = audioToSave.author.firestoreID
            cdAuthor.name = audioToSave.author.name
            cdAuthor.owned = true
            
            cdAudio.author = cdAuthor
            
            group.notify(queue: .main) {
                cdAuthor.profileImageData = authorProfilePictureData
                
                
                    DispatchQueue.main.async {
                do {
                        try managedContext.save()
                        loadFavorites(completion: completion)
                } catch let error as NSError {
                    print("Could not save. \(error), \(error.userInfo)")
                        loadFavorites(completion: completion)
                }
                    }
            }
        }
    }
    
    static func loadFavorites(completion: ((_ favorites: FavoritesTuple?, _ error: Error?) -> Void)? = nil) {
        let managedContext = Favorites.delegate.persistentContainer.viewContext
        
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "favorites_queue", attributes: .concurrent)
        
        group.enter()
        var favoritePeople: [DetailedRabbi]? = nil
        queue.async {
            let fetchRequest = CDPerson.fetchRequest()
            
            if let personEntities = try? managedContext.fetch(fetchRequest) {
                if favoritePeople == nil {
                    favoritePeople = []
                }
                for personEntity in personEntities {
                    if personEntity.owned == false {
                    guard let person = DetailedRabbi(cdPerson: personEntity) else {
                        continue
                    }
                    
                    favoritePeople?.append(person)
                    }
                }
            }
            group.leave()
        }
        
        group.enter()
        var favoriteVideos: [Video]? = nil
        queue.async {
            let fetchRequest = CDVideo.fetchRequest()
            
            if let videoEntities = try? managedContext.fetch(fetchRequest) {
                if favoriteVideos == nil {
                    favoriteVideos = []
                }
                for videoEntity in videoEntities {
                    guard let video = Video(cdVideo: videoEntity) else {
                        continue
                    }
                    
                    favoriteVideos?.append(video)
                }
            }
            group.leave()
        }
        
        
        group.enter()
        var favoriteAudios: [Audio]? = nil
        queue.async {
            let fetchRequest = CDAudio.fetchRequest()
            
            if let audioEntities = try? managedContext.fetch(fetchRequest) {
                if favoriteAudios == nil {
                    favoriteAudios = []
                }
                for audioEntity in audioEntities {
                    guard let audio = Audio(cdAudio: audioEntity) else {
                        continue
                    }
                    
                    favoriteAudios?.append(audio)
                }
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion?((videos: favoriteVideos, audios: favoriteAudios, people: favoritePeople), nil)
        }
    }
}
