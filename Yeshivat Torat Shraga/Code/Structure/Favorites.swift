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
    static unowned let delegate = (UIApplication.shared.delegate as! AppDelegate)
    /*
    static func save(_ audioToSave: Audio, completion: ((_ favorites: (videos: [Video]?, audios: [Audio]?, people: [DetailedRabbi]?)?, _ error: Error?) -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            let group = DispatchGroup()
            
            group.enter()
            var authorProfilePictureData: Data?
            
            let authorProfilePicture = (audioToSave.author as? DetailedRabbi)?.profileImage
            let authorProfilePictureURL = (audioToSave.author as? DetailedRabbi)?.profileImageURL
            
            if let authorProfilePicture = authorProfilePicture {
                DispatchQueue.main.async {
                    guard let data = authorProfilePicture.asUIImage().jpegData(compressionQuality: 1.0) else {
                        completion?((favoriteVideos, favoriteAudios, favoritePeople, favoriteSeries), KHKInternalError.invalidDataProvided)
                        return
                    }
                    authorProfilePictureData = data
                    group.leave()
                }
            } else if let authorProfilePictureURL = authorProfilePictureURL {
                guard let data = try? Data(contentsOf: authorProfilePictureURL) else {
                    DispatchQueue.main.async {
                        completion?((favoriteVideos, favoriteAudios, favoritePeople, favoriteSeries), KHKInternalError.unknownError)
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
            DispatchQueue.main.async {
                if let thumbnail = videoToSave.thumbnail {
                    guard let data = thumbnail.asUIImage().jpegData(compressionQuality: 1.0) else {
                        completion?((favoriteVideos, favoriteAudios, favoritePeople, favoriteSeries), KHKInternalError.invalidDataProvided)
                        return
                    }
                    thumbnailData = data
                    group.leave()
                } else if let thumbnailURL = videoToSave.thumbnailURL {
                    guard let data = try? Data(contentsOf: thumbnailURL) else {
                        DispatchQueue.main.async {
                            completion?((favoriteVideos, favoriteAudios, favoritePeople, favoriteSeries), KHKInternalError.unknownError)
                        }
                        return
                    }
                    thumbnailData = data
                    group.leave()
                } else {
                    videoToSave.getThumbnail { thumbnail in
                        guard let thumbnail = thumbnail else {
                            DispatchQueue.main.async {
                                completion?((favoriteVideos, favoriteAudios, favoritePeople, favoriteSeries), KHKInternalError.unknownError)
                            }
                            return
                        }
                        guard let data = thumbnail.asUIImage().jpegData(compressionQuality: 1.0) else {
                            completion?((favoriteVideos, favoriteAudios, favoritePeople, favoriteSeries), KHKInternalError.invalidDataProvided)
                            return
                        }
                        thumbnailData = data
                        group.leave()
                    }
                }
            }
            
            guard let duration = videoToSave.duration else {
                DispatchQueue.main.async {
                    completion?((favoriteVideos, favoriteAudios, favoritePeople, favoriteSeries), KHKInternalError.invalidDataProvided)
                }
                return
            }
            
            
            let managedContext = delegate.persistentContainer.viewContext
            
            let entity = CDVideo.entity()
            
            let cdVideo = CDVideo(entity: entity,
                                  insertInto: managedContext)
            
            cdVideo.firestoreID = videoToSave.firestoreDocumentID
            cdVideo.fileID = videoToSave.fileID
            cdVideo.url = videoToSave.url
            cdVideo.title = videoToSave.title
            cdVideo.body = videoToSave.description
            cdVideo.categories = videoToSave.categories
            cdVideo.uploadDate = videoToSave.uploadDate
            cdVideo.duration = Int64(duration)
            
            let cdAuthor = CDPerson(context: managedContext)
            cdAuthor.firestoreID = author.firestoreID
            cdAuthor.name = author.name
            cdAuthor.type = author.type?.rawValue
            cdAuthor.owned = true
            
            cdVideo.author = cdAuthor
            
            group.notify(queue: .main) {
                cdVideo.thumbnailData = thumbnailData
                cdAuthor.profileImageData = authorProfilePictureData
                
                do {
                    try managedContext.save()
                    favoriteVideos?.append(videoToSave)
                    DispatchQueue.main.async {
                        completion?((favoriteVideos, favoriteAudios, favoritePeople, favoriteSeries), nil)
                    }
                } catch let error as NSError {
                    print("Could not save. \(error), \(error.userInfo)")
                    DispatchQueue.main.async {
                        completion?((favoriteVideos, favoriteAudios, favoritePeople, favoriteSeries), error)
                    }
                }
            }
        }
    }
    */
    
    
    func loadFavorites(completion: ((_ favorites: (videos: [Video]?, audios: [Audio]?, people: [DetailedRabbi]?)?, _ error: Error?) -> Void)? = nil) {
        let managedContext = Favorites.delegate.persistentContainer.viewContext
        
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "favorites_queue", attributes: .concurrent)
        
        var favoritePeople: [DetailedRabbi]? = nil
        
        queue.async {
            group.enter()
            let fetchRequest = CDPerson.fetchRequest()
            
            if let personEntities = try? managedContext.fetch(fetchRequest) {
                if favoritePeople == nil {
                    favoritePeople = []
                }
                for personEntity in personEntities {
                    if personEntity.owned == false {
                        if let name = personEntity.name, let id = personEntity.firestoreID, let profileImageData = personEntity.profileImageData {
                            guard let profileUIImage = UIImage(data: profileImageData) else {
                                print("Failed to load picture from data for person with Firestore ID '\(id)'")
                                continue
                            }
                            
                            let person = DetailedRabbi(id: id, name: name, profileImage: Image(uiImage: profileUIImage))
                            favoritePeople?.append(person)
                        }
                    }
                }
            }
            group.leave()
        }
        
//        queue.async {
//            group.enter()
//            let fetchRequest = CDVideo.fetchRequest()
//
//            if let videoEntities = try? managedContext.fetch(fetchRequest) {
//                if favoriteVideos == nil {
//                    favoriteVideos = []
//                }
//                for videoEntity in videoEntities {
//                    guard let video = KHKVideo(cdVideo: videoEntity) else {
//                        continue
//                    }
//
//                    favoriteVideos?.append(video)
//                }
//            }
//            group.leave()
//        }
        
        var favoriteVideos: [Video]? = nil
        
        var favoriteAudios: [Audio]? = nil
        
        queue.async {
            group.enter()
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
