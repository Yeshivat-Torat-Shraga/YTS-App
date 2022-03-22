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
                
                VStack {
                    if let favorites = model.favorites, favorites.count > 0 {
                        ForEach(favorites, id: \.self) { favorite in
                            if let video = favorite.video {
                                VideoCardView(video: video)
                                    .contextMenu {
                                        Button("Play") {}
                                    }
                            } else if let audio = favorite.audio {
                                AudioCardView(audio: audio)
                                    .contextMenu {
                                        Button("Play") {}
                                    }
                            }
                        }
                    }
                }
                
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
                 
                LazyVStack {
                    if let sortables = model.sortables {
                        if sortables.count > 0 {
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
                            .padding(.horizontal)
                        } else {
                            VStack {
                                Text("Sorry, no Shiurim were found.")
                                    .bold()
                                    .font(.title2)
                                    .padding(.vertical)
                                Text("\(model.rabbi.name) didn't upload any Shiurim yet.")
                                Text("Check again in a little bit.")
                            }
                            .padding(.vertical)
                        }
                    }
                    
                    LoadMoreView(loadingContent: Binding(get: { model.loadingContent }, set: { model.loadingContent = $0 }), showingError: Binding(get: { model.showError }, set: { model.showError = $0 }), retreivedAllContent: Binding(get: { model.retreivedAllContent }, set: { model.retreivedAllContent = $0 }), loadMore: {
//                        self.model.loadingContent = true
                        let count = 5
                        model.load(next: count)
                    })
                        .padding(.horizontal)
                }
            }
        }
        .onAppear {
            model.initialLoad()
        }
        
        .navigationTitle(model.rabbi.name)
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarTrailing) {
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
    }
}

struct DisplayRabbiView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DisplayRabbiView(rabbi: DetailedRabbi.samples[2])
                .foregroundColor(.shragaBlue)
        }
    }
}
