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

class Favorites: ObservableObject {
    static var shared = Favorites()
    let delegate = (UIApplication.shared.delegate as! AppDelegate)
    typealias FavoritesTuple = (content: [SortableYTSContent]?, people: [DetailedRabbi]?)
    
    private init() {
        loadFavorites()
    }
    
    
    @Published var favoriteIDs: Set<FirestoreID>?
    @Published var favorites: FavoritesTuple?
    
    /// Retreives the most updated favorites tuple for the device.
    func getFavorites(completion: @escaping ((_ favorites: FavoritesTuple?, _ error: Error?) -> Void)) {
        if let favorites = favorites {
            completion(favorites, nil)
        } else {
            self.loadFavorites(completion: completion)
        }
    }
    
    func clearFavorites() {
        let entities = [CDContent.entity(), CDPerson.entity()]
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
    
    func save(_ rabbiToSave: DetailedRabbi, completion: ((_ favorites: FavoritesTuple?, _ error: Error?) -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            
            
            let managedContext = self.delegate.persistentContainer.viewContext
            
            var cdAuthor: CDPerson
            cdAuthor = CDPerson(context: managedContext)
            
            cdAuthor.firestoreID = rabbiToSave.firestoreID
            
            DispatchQueue.main.async {
                do {
                    try managedContext.save()
                    self.loadFavorites(completion: completion)
                } catch let error as NSError {
                    print("Failed to save: \(error), \(error.userInfo)")
                    self.loadFavorites(completion: completion)
                }
            }
            
        }
    }
    
    func save(_ videoToSave: Video, completion: ((_ favorites: FavoritesTuple?, _ error: Error?) -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            let managedContext = self.delegate.persistentContainer.viewContext
            
            let entity = CDContent.entity()
            
            let cdVideo = CDContent(entity: entity,
                                  insertInto: managedContext)
            
            cdVideo.firestoreID = videoToSave.firestoreID
            
            
            
            DispatchQueue.main.async {
                do {
                    try managedContext.save()
                    self.loadFavorites(completion: completion)
                } catch let error as NSError {
                    print("Failed to save: \(error), \(error.userInfo)")
                    self.loadFavorites(completion: completion)
                }
            }
            
        }
    }
    
    func save(_ audioToSave: Audio, completion: ((_ favorites: FavoritesTuple?, _ error: Error?) -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            
            
            
            let managedContext = self.delegate.persistentContainer.viewContext
            
            let entity = CDContent.entity()
            
            let cdAudio = CDContent(entity: entity,
                                  insertInto: managedContext)
            
            cdAudio.firestoreID = audioToSave.firestoreID
            
            
            
            DispatchQueue.main.async {
                do {
                    try managedContext.save()
                    self.loadFavorites(completion: completion)
                } catch let error as NSError {
                    print("Failed to save: \(error), \(error.userInfo)")
                    self.loadFavorites(completion: completion)
                }
            }
        }
    }
    
    func delete(_ rabbiToDelete: DetailedRabbi, completion: ((_ favorites: FavoritesTuple?, _ error: Error?) -> Void)? = nil) {
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
    
    internal func delete(_ videoToDelete: Video, completion: ((_ favorites: FavoritesTuple?, _ error: Error?) -> Void)? = nil) {
        let managedContext = delegate.persistentContainer.viewContext
        let fetchRequest = CDContent.fetchRequest()
        
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
    
    func delete(_ audioToDelete: Audio, completion: ((_ favorites: FavoritesTuple?, _ error: Error?) -> Void)? = nil) {
        let managedContext = delegate.persistentContainer.viewContext
        let fetchRequest = CDContent.fetchRequest()
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
                    loadFavorites(completion: completion)
                }
            } else {
                print("Could not locate a match in CoreData, This likely happened because an erroneous delete request was made.")
                loadFavorites(completion: completion)
            }
        } catch {
            print("Failed to delete: \(error)")
        }
    }
    
    func loadFavorites(completion: ((_ favorites: FavoritesTuple?, _ error: Error?) -> Void)? = nil) {
        var contentIDs: Set<FirestoreID> = []
        var rabbiIDs: Set<FirestoreID> = []
        let managedContext = self.delegate.persistentContainer.viewContext
        
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "favorites_queue", attributes: .concurrent)
        
        var favoritePeople: [DetailedRabbi]? = nil
        group.enter()
        queue.async {
            let fetchRequest = CDPerson.fetchRequest()
            
            if let personEntities = try? managedContext.fetch(fetchRequest) {
                if favoritePeople == nil {
                    favoritePeople = []
                }
                for personEntity in personEntities {
                    guard let firestoreID = personEntity.firestoreID else {
                        print("CD personEntity missing firestoreID")
                        continue
                    }
                    rabbiIDs.insert(firestoreID)
                    
                }
            }
            if rabbiIDs.isEmpty {
                group.leave()
            } else {
                FirebaseConnection.loadRabbisByIDs(rabbiIDs) { rabbis, error in
                    if let rabbis = rabbis {
                        favoritePeople = rabbis
                    } else if let error = error {
                        print("An error occured while loading rabbis from Firestore using CD: \(error.localizedDescription)")
                    }
                    group.leave()
                }
            }
        }
        
        
        var favoriteContents: [SortableYTSContent]? = nil
        group.enter()
        queue.async {
            let fetchRequest = CDContent.fetchRequest()
            
            if let contentEntities = try? managedContext.fetch(fetchRequest) {
                if favoriteContents == nil {
                    favoriteContents = []
                }
                for contentEntity in contentEntities {
                    guard let firestoreID = contentEntity.firestoreID else {
                        print("CD Content entity missing firestoreID")
                        continue
                    }
                    contentIDs.insert(firestoreID)
                }
            }
            
            if contentIDs.isEmpty {
                group.leave()
            } else {
                FirebaseConnection.loadContentByIDs(contentIDs) { results, error in
                    if let results = results {
                        favoriteContents = results
                    } else if let error = error {
                        print("An error occured while loading contents from Firestore using CD: \(error.localizedDescription)")
                        return
                    }
                    group.leave()
                }
            }
            // Must have SortableYTSContent before calling .leave()
        }
        
        group.notify(queue: .main) {
            let favorites = (content: favoriteContents, people: favoritePeople)
            self.favorites = favorites
            self.favoriteIDs = contentIDs.union(rabbiIDs)
            completion?(favorites, nil)
        }
    }
}
