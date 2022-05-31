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
    @Published var uploadProgress: Double = 0.0
    @Published var enableSubmission = false
    @Published var isUploading = false
    @Published var fileDisplayName: String? = nil
    var contentDuration: Int? = nil
    
    func updateSubmissionStatus() {
        enableSubmission = (title.count > 5 &&
                            author.firestoreID != DetailedRabbi.sample.firestoreID &&
                            category.id != Tag.sample.id &&
                            contentURL != nil)
    }
    
    func submitContent() {
        guard let contentURL = contentURL,
              let hash = SHA256.hash(ofFile: contentURL)
        else {
            self.showAlert(title: "An error occurred",
                           body: "There was an issue opening your file for upload. If this is the first time you're seeing this, try again. Otherwise, try uploading a different shiur.")
            return
        }
        
        guard let contentDuration = contentDuration else {
            showAlert(title: "An error occured", body: "There was an issue getting the duration of the selected file. Try again with a different file.")
            return
        }
        
        guard let resources = try? contentURL.resourceValues(forKeys:[.fileSizeKey]),
              let fileSize = resources.fileSize
        else {
            self.showAlert(title: "An error occurred",
                           body: "There was an issue opening your file for upload. If this is the first time you're seeing this, try again. Otherwise, try uploading a different shiur.")
            return
        }
        
        guard fileSize < 524_288_000 else {
            self.showAlert(title: "An error occurred",
                           body: "Please select a file smaller than 500MB.")
            return
        }
        
        FirebaseConnection.submitContent(title: title, contentHash: hash, author: author, category: category, duration: contentDuration) { metadata, error in
            // handle response here
            guard let metadata = metadata else {
                self.showAlert(title: "An error occurred",
                               body: "There was an issue checking if this device is authorized to upload shiurim. If this is the first time you're seeing this, try again. Otherwise, try again later.")
                return
            }
            
            guard metadata["status"]! == "success" else {
                self.showAlert(title: "An error occurred",
                               body: "Your submission was rejected. Check to make sure you filled out all the required fields. If this issue persists, your device may have been blocked from uploading shiurim.")
                return
            }

            self.isUploading = true
            let storageRef = Storage.storage().reference()
            let contentDestinationRef = storageRef.child("user-submissions/\(hash)")
            let uploadTask = contentDestinationRef.putFile(from: contentURL, metadata: nil) { metadata, error in
                guard metadata != nil else {
                    self.showAlert(title: "An error occurred",
                                   body: "Something went wrong and your shiur wasn't submitted. If this is the first time you're seeing this, try again. Otherwise, come back later. If this issue persists, send us an email from the about section.")
                    self.isUploading = false
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
                self.isUploading = false
                self.showAlert(title: "Thank you!",
                               body: "Your submission was successful, and is waiting for review. It will be available for everyone once it is approved.")
                self.resetForm()
            }
            uploadTask.observe(.failure) { snapshot in
                self.isUploading = false
                self.showAlert(title: "An error occured",
                               body: "Something went wrong and your shiur wasn't submitted. If this is the first time you're seeing this, try again. Otherwise, come back later. If this issue persists, send us an email from the about section.")
                
                if let error = snapshot.error as NSError? {
                    print(error.localizedDescription)
                }
                
                self.showAlert(title: "An error occurred",
                               body: "There was an issue uploading your file. If this is the first time you're seeing this, try again. Otherwise, try uploading a different shiur, or come back later.")
                
                self.resetForm()
            }
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
                self.showAlert(title: "An error occured", body: "There was an issue contacting the server. Please try again later.")
                return
            }
            self.rabbis = rebbeim
            group.leave()
        }
        
        
        // Load all Categories
        group.enter()
        FirebaseConnection.loadCategories(flatList: true) { tags, error in
            guard let tags = tags else {
                self.showAlert(title: "An error occured", body: "There was an issue contacting the server. Please try again later.")
                return
            }
            self.tags = tags
            group.leave()
        }
        group.notify(queue: .main) {
            print("done!")
        }
    }
    
    func resetForm() {
        title = ""
        author = DetailedRabbi.sample
        category = .sample
        contentURL = nil
        fileDisplayName = nil
        uploadProgress = 0
    }
    
    func showAlert(title: String, body: String) {
        self.alertTitle = title
        self.alertBody = body
        self.showAlert = true
    }
}
