//
//  SubmitContentModel.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 5/27/22.
//

import SwiftUI
import FirebaseStorage
import FirebaseAnalytics


class SubmitContentModel: ObservableObject {
    @Published var showAlert = false
    @Published var alertTitle: String = ""
    @Published var alertBody: String = ""
    
    @Published var rabbis: [Rabbi]? = nil
    @Published var tags: [Tag]? = nil
    
    @Published var title = ""
    @Published var author: Rabbi = DetailedRabbi.sample
    @Published var category: Tag = .miscellaneous
    @Published var contentURL: URL? = nil
    @Published var uploadProgress: Double = 0.0
    @Published var isUploading = false
    @Published var fileDisplayName: String? = nil
    var contentDuration: Int? = nil
    
    var enableSubmission: Bool {
        return (title.count > 3 &&
                author.firestoreID != DetailedRabbi.sample.firestoreID &&
                contentURL != nil)
    }
    
    func submitContent() {
        self.isUploading = true
        self.objectWillChange.send()
        
        guard let contentURL = contentURL else {
            Analytics.logEvent("upload_failure", parameters: ["reason": "url nil"])
            self.isUploading = false
            self.showAlert(title: "Uploading Error",
                           body: "There was an issue locating your file. If this is the first time you're seeing this, try again. Otherwise, try uploading a different shiur.")
            return
        }
        
        print("Content URL: \(contentURL)")
        
        print("Unlocked resource: \(contentURL.startAccessingSecurityScopedResource())")
        
        guard let hash = SHA256.hash(ofFile: contentURL) else {
            Analytics.logEvent("upload_failure", parameters: ["reason": "hash calculation failure"])
            self.isUploading = false
            self.showAlert(title: "Uploading Error",
                           body: "There was an issue opening your file for upload. If this is the first time you're seeing this, try again. Otherwise, try uploading a different shiur.")
            return
        }
        
        guard let contentDuration = contentDuration else {
            Analytics.logEvent("upload_failure", parameters: ["reason": "hash calculation failure"])
            self.isUploading = false
            showAlert(title: "Uploading Error", body: "There was an issue getting the duration of the selected file. Try again with a different file.")
            return
        }
        
        guard let resources = try? contentURL.resourceValues(forKeys:[.fileSizeKey]),
              let fileSize = resources.fileSize
        else {
            Analytics.logEvent("upload_failure", parameters: ["reason": "filesize evaluation failure"])
            self.showAlert(title: "Uploading Error",
                           body: "There was an issue handling your file for upload. If this is the first time you're seeing this, try again. Otherwise, try uploading a different shiur.")
            return
        }
        
        guard fileSize < 262_144_000 else {
            Analytics.logEvent("upload_failure", parameters: ["reason": "file too large", "filesize": fileSize])
            self.isUploading = false
            self.showAlert(title: "Uploading Error",
                           body: "Please make sure the audio file is smaller than 250MB.")
            return
        }
        
        FirebaseConnection.submitContent(title: title, author: author, category: category, duration: contentDuration, contentHash: hash) { metadata, error in
            // handle response here
            guard let metadata = metadata else {
                Analytics.logEvent("upload_failure", parameters: ["reason": "nil response from submitContent GCF"])
                self.isUploading = false
                self.showAlert(title: "Uploading Error",
                               body: "There was an issue checking if this device is authorized to upload shiurim. If this is the first time you're seeing this, try again. Otherwise, try again later.")
                return
            }
            
            guard metadata["status"]! == "success" else {
                Analytics.logEvent("upload_failure", parameters: ["reason": "rejected by GCF"])
                self.isUploading = false
                self.showAlert(title: "Uploading Error",
                               body: "Your submission failed. Check to make sure you filled out all the required fields. If this issue persists, contact us.")
                return
            }
            
            let storageRef = Storage.storage().reference()
            let contentDestinationRef = storageRef.child("user-submissions/\(hash)")
            contentURL.startAccessingSecurityScopedResource()
            
            guard let data = try? Data(contentsOf: contentURL) else {
                self.isUploading = false
                self.showAlert(title: "Uploading Error",
                               body: "Something went wrong and your shiur couldn't be read. If this is the first time you're seeing this, try again. Otherwise, try a different shiur.")
                return
            }
            
            let sm = StorageMetadata()
            sm.contentType = "audio/\(contentURL.pathExtension)"
            
            let uploadTask = contentDestinationRef.putData(data, metadata: sm) { metadata, error in
                guard metadata != nil else {
                    Analytics.logEvent("upload_failure", parameters: ["reason": "nil metadata while uploading to storage"])
                    self.isUploading = false
                    self.showAlert(title: "Uploading Error",
                                   body: "Something went wrong and your shiur wasn't submitted. If this is the first time you're seeing this, try again. Otherwise, come back later. If this issue persists, contact us.")
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
                Analytics.logEvent("upload_success", parameters: nil)
                self.isUploading = false
                self.showAlert(title: "Thank You!",
                               body: "Your submission was successfully uploaded and is waiting for review. It will be publicly available once it is approved.")
                self.resetForm()
            }
            
            uploadTask.observe(.failure) { snapshot in
                self.isUploading = false
                self.showAlert(title: "Uploading Error",
                               body: "Something went wrong and your shiur wasn't submitted. If this is the first time you're seeing this, try again. Otherwise, come back later. If this issue persists, send us an email from the about section.")
                
                if let error = snapshot.error as NSError? {
                    Analytics.logEvent("upload_failure", parameters: ["reason": error.localizedFailureReason ?? "no reason provided", "error": error.localizedDescription])
                    print(error.localizedDescription)
                }
                
                self.showAlert(title: "Uploading Error",
                               body: "There was an issue uploading your file. If this is the first time you're seeing this, try again. Otherwise, try uploading a different shiur, or come back later.")
                
//                self.resetForm()
            }
        }
    }
    
    
    func load() {
        let group = DispatchGroup()
        
        // Load all Rabbis
        group.enter()
        FirebaseConnection.loadRebbeim(options: (limit: -1, includePictureURLs: false, startAfterDocumentID: nil)) { result, error in
            guard let rebbeim = result?.rebbeim else {
                self.showAlert(title: "Error", body: "There was an issue contacting the server. Please try again later.")
                return
            }
            self.rabbis = rebbeim
            group.leave()
        }
        
        
        // Load all Categories
        group.enter()
        FirebaseConnection.loadCategories(flatList: true) { tags, error in
            guard let tags = tags else {
                self.showAlert(title: "Error", body: "There was an issue contacting the server. Please try again later.")
                return
            }
            self.tags = tags
            group.leave()
        }
        
        group.notify(queue: .main) {
        }
    }
    
    func loadOnlyIfNeeded() {
        if self.tags == nil && self.rabbis == nil {
            self.load()
        }
    }
    
    func resetForm() {
        title = ""
        author = DetailedRabbi.sample
        category = .miscellaneous
        contentURL = nil
        fileDisplayName = nil
        uploadProgress = 0
    }
    
    func showAlert(title: String, body: String) {
        self.uploadProgress = 0.0
        self.alertTitle = title
        self.alertBody = body
        self.showAlert = true
    }
}

