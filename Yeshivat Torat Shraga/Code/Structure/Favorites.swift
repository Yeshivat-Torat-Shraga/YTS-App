//
//  Favorites.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 1/6/22.
//

import Foundation
import UIKit
import SwiftUI
import CoreData

class Favorites {
    static let delegate = (UIApplication.shared.delegate as! AppDelegate)
    typealias FavoritesTuple = (videos: [Video]?, audios: [Audio]?, people: [DetailedRabbi]?)
    
    private static var favorites: FavoritesTuple?// = loadFavorites()
    static func getfavoriteIDs() -> [FirestoreID] {
        var IDs: [FirestoreID] = []
        if let favorites = self.favorites ?? loadFavorites() {
            if let videos = favorites.videos {
                for video in videos {
                    IDs.append(video.firestoreID)
                }
            }
            if let audios = favorites.audios {
                for audio in audios {
                    IDs.append(audio.firestoreID)
                }
            }
            if let people = favorites.people {
                for person in people {
                    IDs.append(person.firestoreID)
                }
            }
        }
        return IDs
    }
    
    /// Retreives the most updated favorites tuple for the device.
    static func getFavorites(completion: @escaping ((_ favorites: FavoritesTuple?, _ error: Error?) -> Void)) {
        if let favorites = favorites {
            completion(favorites, nil)
        } else {
            loadFavorites(completion: completion)
        }
    }
    
    static func clearFavorites() {
        let entities = [CDVideo.entity(), CDAudio.entity(), CDPerson.entity()]
        for entity in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity.name!)
            let deleteReqest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            do {
                try delegate.persistentContainer.viewContext.execute(deleteReqest)
            } catch {
                print(error)
            }
        }
    }
    
    static func save(_ rabbiToSave: DetailedRabbi, completion: ((_ favorites: FavoritesTuple?, _ error: Error?) -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            let group = DispatchGroup()
            
            group.enter()
            var profilePictureData: Data?
            
            let profilePicture = rabbiToSave.profileImage
            let profilePictureURL = rabbiToSave.profileImageURL
            
            if let profilePicture = profilePicture {
                DispatchQueue.main.async {
                    guard let data = profilePicture.asUIImage().jpegData(compressionQuality: 1.0) else {
                        DispatchQueue.main.async {
                            loadFavorites(completion: completion)
                        }
                        return
                    }
                    profilePictureData = data
                    group.leave()
                }
            } else if let profilePictureURL = profilePictureURL {
                guard let data = try? Data(contentsOf: profilePictureURL) else {
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
                        print("Failed to save: \(error), \(error.userInfo)")
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
            cdVideo.favoritedAt = videoToSave.favoritedAt
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
                        print("Failed to save: \(error), \(error.userInfo)")
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
            cdAudio.favoritedAt = audioToSave.favoritedAt
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
                        print("Failed to save: \(error), \(error.userInfo)")
                        loadFavorites(completion: completion)
                    }
                }
            }
        }
    }
    
    static func delete(_ rabbiToDelete: DetailedRabbi, completion: ((_ favorites: FavoritesTuple?, _ error: Error?) -> Void)? = nil) {
        let managedContext = delegate.persistentContainer.viewContext
        let fetchRequest = CDPerson.fetchRequest()
        
        do {
            let result = try managedContext.fetch(fetchRequest)
            
            if let match = result.first(where: { r in
                r.firestoreID == rabbiToDelete.firestoreID
            }) {
                managedContext.delete(match)
                
                do {
                    try managedContext.save()
                    loadFavorites(completion: completion)
                } catch {
                    print("Failed to delete: \(error)")
                    loadFavorites(completion: completion)
                }
            }
        } catch {
            print("Failed to delete: \(error)")
        }
    }
    
    static func delete(_ videoToDelete: Video, completion: ((_ favorites: FavoritesTuple?, _ error: Error?) -> Void)? = nil) {
        let managedContext = delegate.persistentContainer.viewContext
        let fetchRequest = CDVideo.fetchRequest()
        
        do {
            let result = try managedContext.fetch(fetchRequest)
            
            if let match = result.first(where: { v in
                v.firestoreID == videoToDelete.firestoreID
            }) {
                managedContext.delete(match)
                
                do {
                    try managedContext.save()
                    loadFavorites(completion: completion)
                } catch {
                    print("Failed to delete: \(error)")
                    loadFavorites(completion: completion)
                }
            }
        } catch {
            print("Failed to delete: \(error)")
        }
    }
    
    static func delete(_ audioToDelete: Audio, completion: ((_ favorites: FavoritesTuple?, _ error: Error?) -> Void)? = nil) {
        let managedContext = delegate.persistentContainer.viewContext
        let fetchRequest = CDAudio.fetchRequest()
        
        do {
            let result = try managedContext.fetch(fetchRequest)
            
            if let match = result.first(where: { a in
                a.firestoreID == audioToDelete.firestoreID
            }) {
                managedContext.delete(match)
                
                do {
                    try managedContext.save()
                    loadFavorites(completion: completion)
                } catch {
                    print("Failed to delete: \(error)")
                    loadFavorites(completion: completion)
                }
            }
        } catch {
            print("Failed to delete: \(error)")
        }
    }
    
    private static func loadFavorites(completion: ((_ favorites: FavoritesTuple?, _ error: Error?) -> Void)? = nil) {
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
            let favorites = (videos: favoriteVideos, audios: favoriteAudios, people: favoritePeople)
            self.favorites = favorites
            completion?(favorites, nil)
        }
    }
    
    private static func loadFavorites() -> FavoritesTuple? {
        let managedContext = Favorites.delegate.persistentContainer.viewContext
        
        var favoritePeople: [DetailedRabbi]? = nil
        let peopleFetchRequest = CDPerson.fetchRequest()
        
        if let personEntities = try? managedContext.fetch(peopleFetchRequest) {
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
        
        var favoriteVideos: [Video]? = nil
        let videoFetchRequest = CDVideo.fetchRequest()
        
        if let videoEntities = try? managedContext.fetch(videoFetchRequest) {
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
        
        var favoriteAudios: [Audio]? = nil
        let audioFetchRequest = CDAudio.fetchRequest()
        
        if let audioEntities = try? managedContext.fetch(audioFetchRequest) {
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
        
        let favorites = (videos: favoriteVideos, audios: favoriteAudios, people: favoritePeople)
        self.favorites = favorites
        return favorites
    }
}
