//
//  SubmitContentView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 5/26/22.
//

import SwiftUI
import FirebaseStorage

struct SubmitContentView: View {
    @State private var showingDocumentSelectSheet = false
    @State private var fileDisplayName: String? = nil
    @State private var url = URL(string: "")
    @ObservedObject private var model = SubmitContentModel()
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section {
                        TextField("Title", text: $model.title, onCommit: {model.updateSubmissionStatus()})
                        Picker(selection: $model.author, label: Text("Select an author")) {
                            if let rabbis = model.rabbis {
                                ForEach(rabbis, id: \.firestoreID) { rabbi in
                                    Text(rabbi.name)
                                        .tag(rabbi)
                                }
                            }
                        }
                        
                        
                        Picker(selection: $model.category, label: Text("Select a category")) {
                            if let tags = model.tags {
                                ForEach(tags, id: \.id) { tag in
                                    Text(tag.name)
                                        .tag(tag)
                                }
                            }
                        }
                        
                        // Picker or navlink for author selection
                        // Picker or navlink for category selection
                        Button(action: {showingDocumentSelectSheet = true}) {
                            if let fileDisplayName = fileDisplayName {
                                Text(fileDisplayName)
                            } else {
                                Text("Select a file to upload")
                                    .italic()
                            }
                        }
                    }
                    Section(footer: Text("Once you submit a shiur, you cannot edit it or delete it. All content will be reviewed by YTS staff.")) {
                        if !model.isUploading {
                            Button(action: {
                                if (model.title.count > 5  &&
                                    model.author.firestoreID != DetailedRabbi.sample.firestoreID &&
                                    model.category.id != Tag.sample.id &&
                                    model.contentURL != nil) {
                                    model.submitContent(title: model.title,
                                                        author: model.author,
                                                        contentURL: model.contentURL!,
                                                        category: model.category)
                                }
                            }) {
                                Text("Submit shiur")
                            }
                            .foregroundColor((model.title.count > 5  &&
                                              model.author.firestoreID != DetailedRabbi.sample.firestoreID &&
                                              model.category.id != Tag.sample.id &&
                                              model.contentURL != nil) ? .blue : .gray)
                            .disabled(!(model.title.count > 5  &&
                                        model.author.firestoreID != DetailedRabbi.sample.firestoreID &&
                                        model.category.id != Tag.sample.id &&
                                        model.contentURL != nil))
                            
                        } else {
                            ProgressView(value: model.uploadProgress)
                        }
                    }
                    
                }
                .fileImporter(isPresented: $showingDocumentSelectSheet,
                              allowedContentTypes: [.audio, .audiovisualContent, .data]) { result in
                    guard let url = try? result.get() else {
                        // Show an error alert or something
                        return
                    }
                    model.contentURL = url
                    fileDisplayName = url.pathComponents.last!
                    //                    model.updateSubmissionStatus()
                }
            }
            .navigationTitle("New Shiur")
        }
        .onAppear {
            model.loadOnlyIfNeeded()
        }
        .alert(isPresented: $model.showAlert) {
            Alert(title: Text(model.alertTitle), message: Text(model.alertBody), dismissButton: Alert.Button.cancel(Text("OK")))
        }
    }
}

struct SubmitContentView_Previews: PreviewProvider {
    static var previews: some View {
        SubmitContentView()
    }
}
