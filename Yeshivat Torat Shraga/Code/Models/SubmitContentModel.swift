//
//  SubmitContentModel.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 5/27/22.
//

import SwiftUI
import FirebaseStorage


class SubmitContentModel: ObservableObject {
    @Published var showAlert = false
    @Published var alertTitle: String = ""
    @Published var alertBody: String = ""
    @Published var rabbis: [Rabbi]? = nil
    @Published var tags: [Tag]? = nil
    @Published var title = ""
    @Published var author: Rabbi = DetailedRabbi.sample
    @Published var category: Tag = .sample
    @Published var contentURL: URL? = nil
    @Published var uploadProgress: Double = 0
    @Published var enableSubmission = false
    @Published var isUploading = false
    
    
    func updateSubmissionStatus() {
        enableSubmission = (title.count > 5  &&
                            author.firestoreID != DetailedRabbi.sample.firestoreID &&
                            category.id != Tag.sample.id &&
                            contentURL != nil)
    }
    
    func submitContent(title: String, author: Rabbi, contentURL: URL, category: Tag) {
        self.isUploading = true
        guard let hash = SHA256.hash(ofFile: contentURL) else {
            self.alertTitle = "An error occurred"
            self.alertBody = "There was an issue opening your file for upload. If this is the first time you're seeing this, try again. Otherwise, try uploading a different shiur."
            self.showAlert = true
            self.isUploading = false
            // This will fail if the file is inacessable
            // Make this class conform to ErrorShower
            return
        }
        FirebaseConnection.submitContent(title: title, contentHash: hash, author: author, category: category) { metadata, error in
            // handle response here
        }
        let storageRef = Storage.storage().reference()
        let contentDestinationRef = storageRef.child("userSubmissions/\(hash)")
        let uploadTask = contentDestinationRef.putFile(from: contentURL, metadata: nil) { metadata, error in
            guard metadata != nil else {
                self.alertTitle = "An error occurred"
                self.alertBody = "Something went wrong and your shiur wasn't submitted. If this is the first time you're seeing this, try again. Otherwise, come back later. If this issue persists, send us an email from the about section."
                self.showAlert = true
                return
            }
        }
        uploadTask.observe(.progress) { snapshot in
            withAnimation {
                self.uploadProgress = Double(snapshot.progress!.completedUnitCount)
                / Double(snapshot.progress!.totalUnitCount)
            }
        }
        uploadTask.observe(.success) { snapshot in
            self.alertTitle = "Thank you!"
            self.alertBody = "Your submission was successful, and is waiting for review. It will be available for everyone once it is approved."
            self.showAlert = true
            self.isUploading = false
        }
        uploadTask.observe(.failure) { snapshot in
            self.isUploading = false
            self.alertTitle = "An error occurred"
            self.alertBody = "Something went wrong and your shiur wasn't submitted. If this is the first time you're seeing this, try again. Otherwise, come back later. If this issue persists, send us an email from the about section."
            if let error = snapshot.error as? NSError {
                self.alertBody += " (\(error.code))"
                print(error.localizedDescription)
            }
            self.showAlert = true
            // Show alert here
        }
        
        
    }
    
    func loadOnlyIfNeeded() {
        if self.tags == nil && self.rabbis == nil {
            self.load()
        }
    }
    
    func load() {
        let group = DispatchGroup()
        
        // Load all Rabbis
        group.enter()
        FirebaseConnection.loadRebbeim(options: (limit: -1, includePictureURLs: false, startAfterDocumentID: nil)) { result, error in
            guard let rebbeim = result?.rebbeim else {
                // Show alert here
                return
            }
            self.rabbis = rebbeim
            group.leave()
        }
        
        
        // Load all Categories
        group.enter()
        FirebaseConnection.loadCategories(flatList: true) { tags, error in
            guard let tags = tags else {
                // Show alert here
                return
            }
            self.tags = tags
            group.leave()
        }
        group.notify(queue: .main) {
            print("done!")
        }
    }
}
