//
//  DisplayRabbiView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/16/21.
//

import SwiftUI

struct DisplayRabbiView: View {
    @ObservedObject var model: DisplayRabbiModel
    @EnvironmentObject var favoritesManager: Favorites
    
    init(rabbi: DetailedRabbi) {
        model = DisplayRabbiModel(rabbi: rabbi)
    }
    
    var body: some View {
        ScrollView {
            Group {
                if let favorites = model.favoriteContent, favorites.count > 0 {
                    LabeledDivider(title: "Favorites")
                    
                    VStack {
                        ForEach(favorites, id: \.self) { favorite in
                            if let video = favorite.video {
                                VideoCardView(video: video)
                            } else if let audio = favorite.audio {
                                AudioCardView(audio: audio)
                            }
                        }
                    }
//                    Divider()
                }
            }
            .padding(.horizontal)
            
            Spacer()
            Spacer()
            Spacer()
            
            Group {
                LazyVStack {
                    if let sortables = model.sortables {
                        if sortables.count > 0 {
                            LabeledDivider(title: "Recently Uploaded")
                            
                            ForEach(sortables, id: \.self) { sortable in
                                if let video = sortable.video {
                                    VideoCardView(video: video)
//                                        .contextMenu {
//                                            Button("Play") {}
//                                        }
                                } else if let audio = sortable.audio {
                                    AudioCardView(audio: audio)
//                                        .contextMenu {
//                                            Button("Play") {}
//                                        }
                                }
                            }
                        } else {
                            VStack {
                                Text("Sorry, no shiurim here yet.")
                                    .bold()
                                    .font(.title2)
                                
                                Spacer().frame(height: 6)
                                
                                Text("Check again in a little bit.")
                            }
                            .multilineTextAlignment(.center)
                        }
                    }
                    
                    LoadMoreView(loadingContent: $model.loadingContent,
                                 showingError: $model.showError,
                                 retreivedAllContent: $model.retreivedAllContent,
                                 loadMore: { model.load(next: 5) }
                    )
                }
            }
            .padding(.horizontal)
        }
        .onChange(of: self.favoritesManager.favoriteIDs) { _ in
            model.favoritesManager = favoritesManager
            model.loadFavorites()
        }
        .onAppear {
            model.favoritesManager = favoritesManager
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
            DisplayRabbiView(rabbi: DetailedRabbi.sample)
                .environmentObject(Favorites())
                .foregroundColor(.shragaBlue)
        }
    }
}
