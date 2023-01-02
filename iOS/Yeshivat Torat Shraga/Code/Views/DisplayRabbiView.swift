//
//  DisplayRabbiView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/16/21.
//

import SwiftUI
import FirebaseAnalytics

struct DisplayRabbiView: View {
    @ObservedObject var model: DisplayRabbiModel
    @EnvironmentObject var favoritesManager: Favorites
    @EnvironmentObject var audioPlayerModel: AudioPlayerModel
    
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
                    
                    
                    Spacer()
                    Spacer()
                    Spacer()
                }
            }
            .padding(.horizontal)
            
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
                            HStack {
                                Spacer()
                                VStack {
                                    Text("Sorry, no shiurim here yet.")
                                        .bold()
                                        .font(.title3)
                                    
                                    Spacer()
                                    
                                    Text("Check again in a little bit.")
                                }
                                .multilineTextAlignment(.center)
                                .padding()
                                Spacer()
                            }
                            .background(Color(UIColor.systemGray4))
                            .cornerRadius(UI.cornerRadius)
                            .shadow(radius: UI.shadowRadius)
                        }
                    }
                    
                    LoadMoreView(loadingContent: $model.loadingContent,
                                 showingError: $model.showError,
                                 retreivedAllContent: $model.retreivedAllContent,
                                 loadMore: { model.load() }
                    )
                }
            }
            .padding(.horizontal)
            
            if audioPlayerModel.audio != nil {
                Spacer().frame(height: UI.playerBarHeight)
            }
        }
        .onChange(of: self.favoritesManager.favoriteIDs) { _ in
            model.favoritesManager = favoritesManager
            model.loadFavorites()
        }
        .onAppear {
            model.favoritesManager = favoritesManager
            model.initialLoad()
            Analytics.logEvent("opened_view", parameters: [
                "page_name": "DisplayRabbi"
            ])
            Analytics.logEvent("opened_rabbi_page", parameters: [
                "name": model.rabbi.name
            ])
            
            
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
        .alert(isPresented: $model.showError, content: {
            Alert(
                title: Text("Error"),
                message: Text(model.errorToShow?.getUIDescription() ?? "We're not even sure what it is, but something is definitely not working. Sorry."),
                dismissButton: Alert.Button.default(
                    Text("Retry"), action: {
                        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                            self.model.retry?()
                        }
                    }))
        })
        
        
    }
}

struct DisplayRabbiView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DisplayRabbiView(rabbi: DetailedRabbi.sample)
                .environmentObject(Favorites())
                .environmentObject(AudioPlayerModel(player: Player()))
                .environmentObject(Player())
                .foregroundColor(.shragaBlue)
        }
    }
}
