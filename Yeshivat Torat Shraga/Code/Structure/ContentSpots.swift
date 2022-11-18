//
//  ContentSpots.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 11/18/22.
//

import Foundation
import UIKit

class ContentSpots {
    static let delegate = (UIApplication.shared.delegate as! AppDelegate)
    
    static func save(content: any YTSContent, spot newSpot: TimeInterval) {
        let managedContext = self.delegate.persistentContainer.viewContext
//        DispatchQueue.global(qos: .background).async {
        if let cdSpots = getCDSpots(content: content), cdSpots.count == 1 {
                let cdSpot = cdSpots[0]
            cdSpot.spot = Int32(newSpot - 2)
        } else {
            delete(content: content)
            
            let entity = CDSpot.entity()
            
            let cdSpot = CDSpot(entity: entity,
                                insertInto: managedContext)
            
            cdSpot.contentFirestoreId = content.firestoreID
            cdSpot.spot = Int32(newSpot - 2)
        }
            
//            DispatchQueue.main.async {
                do {
                    try managedContext.save()
                } catch {
                    print("Failed to save: \(error)")
                }
//            }
//        }
    }
    
    static func delete(content: any YTSContent) {
        let managedContext = self.delegate.persistentContainer.viewContext
//        DispatchQueue.global(qos: .background).async {
            let fetchRequest = CDSpot.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "contentFirestoreId == %@", content.firestoreID)
            
            DispatchQueue.main.async {
                do {
                    let results = try managedContext.fetch(fetchRequest)
                    
                    for result in results {
                        managedContext.delete(result)
                    }
                    try managedContext.save()
                } catch {
                    print("Failed to delete: \(error)")
                }
            }
//        }
    }
    
    static func getSpot(content: any YTSContent) -> TimeInterval? {
        //        DispatchQueue.global(qos: .background).async {
        if let spots = getCDSpots(content: content), spots.count > 0 {
            return TimeInterval(spots[0].spot)
        } else {
            return nil
        }
        //        }
    }
    
    private static func getCDSpots(content: any YTSContent) -> [CDSpot]? {
        //        DispatchQueue.global(qos: .background).async {
//        DispatchQueue.main.async {
            let managedContext = ContentSpots.delegate.persistentContainer.viewContext
            let fetchRequest = CDSpot.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "contentFirestoreId == %@", content.firestoreID)
            return try? managedContext.fetch(fetchRequest)
//        }
        //        }
    }
}
