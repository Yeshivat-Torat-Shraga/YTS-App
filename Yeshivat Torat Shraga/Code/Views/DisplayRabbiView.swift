//
//  DisplayRabbiView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/16/21.
//

import SwiftUI

struct DisplayRabbiView: View {
    @ObservedObject var model: DisplayRabbiModel
    
    init(rabbi: DetailedRabbi) {
        model = DisplayRabbiModel(rabbi: rabbi)
    }
    
    var body: some View {
        ScrollView {
            Group {
                HStack {
                    Text("Favorites")
                        .font(.title3)
                        .bold()
                    Spacer()
                }
                .padding()
                Divider()
            }
            Group {
                HStack {
                    Text("Recently Uploaded")
                        .font(.title3)
                        .bold()
                    Spacer()
                }
                .padding(.horizontal)
                VStack {
                    
                    if let sortables = model.sortables {
                        ForEach(sortables, id: \.self) { sortable in
                            if let video = sortable.video {
                                VideoCardView(video: video)
                                    .contextMenu {
                                        Button("Play") {}
                                    }
                            } else if let audio = sortable.audio {
                                AudioCardView(audio: audio)
                                    .contextMenu {
                                        Button("Play") {}
                                    }
                            }
                        }
                    }                    
                }
                .padding(.horizontal)
            }
        }
        
        .navigationTitle(model.rabbi.name)
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarLeading) {
                LogoView(size: .small)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                DownloadableImage(object: model.rabbi)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .shadow(radius: UI.shadowRadius)
            }
        })
        .onAppear {
            self.model.load()
        }
    }
}

struct DisplayRabbiView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DisplayRabbiView(rabbi: DetailedRabbi.samples[2])
        }
    }
}
