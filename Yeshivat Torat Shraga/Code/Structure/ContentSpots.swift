//
//  ContentSpots.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 11/18/22.
//

import Foundation
import UIKit

class ContentSpots {
    let delegate = (UIApplication.shared.delegate as! AppDelegate)
    
    func save(content: any YTSContent, spot: TimeInterval) {
        DispatchQueue.global(qos: .background).async {
            let managedContext = self.delegate.persistentContainer.viewContext
            
            let entity = CDSpot.entity()
            
            let cdSpot = CDSpot(entity: entity,
                                insertInto: managedContext)
            
            cdSpot.contentFirestoreId = content.firestoreID
            cdSpot.spot = Int32(spot - 5)
            
            do {
                try managedContext.save()
            } catch {
                print("Failed to save: \(error)")
            }
        }
    }
    
    func delete(content: any YTSContent) {
        DispatchQueue.global(qos: .background).async {
            let managedContext = self.delegate.persistentContainer.viewContext
            let fetchRequest = CDSpot.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "contentFirestoreId == %@", content.firestoreID)
            
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
    }
    
    func getSpot(content: any YTSContent) -> TimeInterval? {
//        DispatchQueue.global(qos: .background).async {
        if let spots = getCDSpots(content: content) {
            return TimeInterval(spots[0].spot)
        } else {
            return nil
        }
//        }
    }
    
    private func getCDSpots(content: any YTSContent) -> [CDSpot]? {
//        DispatchQueue.global(qos: .background).async {
            let managedContext = self.delegate.persistentContainer.viewContext
            let fetchRequest = CDSpot.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "contentFirestoreId == %@", content.firestoreID)
            return try? managedContext.fetch(fetchRequest)
//        }
    }
}
