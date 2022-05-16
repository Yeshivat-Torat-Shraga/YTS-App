//
//  FavoritesCardView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 06/02/2022.
//

import SwiftUI

struct SortableFavoriteCardView<Content: SortableYTSContent>: View {
    let content: Content
    var body: some View {
        if let audio = content.audio {
            FavoritesCardView(content: audio)
        } else if let video = content.video {
            FavoritesCardView(content: video)
        }
    }
}

struct FavoritesCardView<Content: YTSContent>: View {
    @EnvironmentObject var favoritesManager: Favorites
    @EnvironmentObject var audioPlayerModel: AudioPlayerModel
    @EnvironmentObject var player: Player
    @Environment(\.colorScheme) var colorScheme
    @State var isShowingPlayerSheet = false
    @State private var isFavoritesBusy = false
    @State private var heartFillOverride = false
    
    let content: Content
    let isAudio: Bool
    
    init(content: Content) {
        self.content = content
        self.isAudio = (content.sortable.audio != nil)
    }
    
    var body: some View {
        Group {
            Button(action: {
                if isAudio {
                    audioPlayerModel.play(audio: content.sortable.audio!)
                    isShowingPlayerSheet = true
                } else {
                    //                 Video Player goes here
                }
            }) {
                HStack(alignment: .center) {
                    Group {
                        if let author = content.author as? DetailedRabbi {
                            DownloadableImage(object: author)
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 85, height: 85)
                                .clipped()
                        } else {
                            Image("Logo")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 85, height: 85)
                                .clipped()
                        }
                    }
                    .background(UI.cardBlueGradient)
                    
                    VStack(alignment: .leading) {
                        Spacer()
                        
                        Text(content.title)
                            .font(.headline)
                            .bold()
                            .minimumScaleFactor(0.6)
                            .foregroundColor(Color("ShragaBlue"))
                            .multilineTextAlignment(.leading)
                        //                    Text("")
                        //                    Text(content.hashValue.description)
                        //                    .foregroundColor(.black)
                        
                        Spacer()
                        
                        HStack {
                            if let date = content.date {
                                if let month = Date.monthNameFor(date.get(.month), short: true) {
                                    HStack {
                                        let yearAsString = String(date.get(.year))
                                        Image(systemName: "calendar")
                                        Text("\(month) \(date.get(.day)), \(yearAsString)")
                                            .foregroundColor(Color("Gray"))
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            HStack {
                                Text(timeFormattedMini(totalSeconds: content.duration ?? 0))
                                    .foregroundColor(Color("Gray"))
                                Image(systemName: "clock")
                            }
                            .padding(.trailing, 5)
                        }
                        .font(.caption)
                        .foregroundColor(Color("Gray"))
                        .padding(.top, 1)
                        
                        Spacer()
                    }
                    Spacer()
                }
            }
            .background(Color.cardViewBG)
            .cornerRadius(UI.cornerRadius)
            .overlay(
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: getFillState("bookmark"))
                            .foregroundColor(.shragaGold)
                            .padding(5)
                            .offset(y: -8)
                            .shadow(radius: UI.shadowRadius)
                    }
                    Spacer()
                }
            )
        }
//        .contextMenu {
//            if let audio = self.content as? Audio {
//                if let favoriteIDs = favoritesManager.favoriteIDs {
//                    Button(action: {
//                        if !isFavoritesBusy {
//                            heartFillOverride = false
//                            isFavoritesBusy = true
//                            
//                            if favoriteIDs.contains(content.firestoreID) {
//                                self.favoritesManager.delete(audio) { favorites, error in
//                                    isFavoritesBusy = false
//                                }
//                            } else {
//                                heartFillOverride = true
//                                self.favoritesManager.save(audio) { favorites, error in
//                                    isFavoritesBusy = false
//                                }
//                            }
//                        }
//                    }) {
//                        Label(isFavoritesBusy
//                              ? heartFillOverride
//                              ? "heart.fill"
//                              : "heart"
//                              
//                              : favoriteIDs.contains(audio.firestoreID)
//                              ? "Unfavorite"
//                              : "Favorite",
//                              
//                              systemImage: isFavoritesBusy
//                              ? heartFillOverride
//                              ? "heart.fill"
//                              : "heart"
//                              
//                              : favoriteIDs.contains(audio.firestoreID)
//                              ? "heart.fill"
//                              : "heart")
//                    }
//                }
//                
//                Button(action: {
//                    audioPlayerModel.play(audio: audio)
//                    isShowingPlayerSheet = true
//                }) {
//                    Label("Play", systemImage: "play")
//                }
//            } else {
//                fatalError("Only accepting audios at this time.")
//            }
//        }
        .sheet(isPresented: $isShowingPlayerSheet) {
            AudioPlayer()
                .environmentObject(audioPlayerModel)
                .environmentObject(favoritesManager)
                .environmentObject(player)
        }
    }
    
    func getFillState(_ imageName: String, invert: Bool = false) -> String {
        var shouldFill = false
        var adaptedName = imageName
        if colorScheme == .light {
            shouldFill = true
        }
        if invert {
            shouldFill.toggle()
        }
        if shouldFill{
            adaptedName += ".fill"
        }
        return adaptedName
    }
}

struct FavoritesCardView_Previews: PreviewProvider {
    static var player = Player()
    static var previews: some View {
        ZStack {
            Color("FavoritesBG").ignoresSafeArea()
            VStack {
                SortableFavoriteCardView(content: SortableYTSContent(audio: Audio.sample))
                SortableFavoriteCardView(content: SortableYTSContent(audio: Audio.sample))
                SortableFavoriteCardView(content: SortableYTSContent(audio: Audio.sample))
                SortableFavoriteCardView(content: SortableYTSContent(audio: Audio.sample))
                SortableFavoriteCardView(content: SortableYTSContent(audio: Audio.sample))
                //                SortableFavoritesCardView(content: SortableYTSContent(video: Video.sample))
            }
            .shadow(radius: UI.shadowRadius)
            .padding(.horizontal)
        }
        .environmentObject(AudioPlayerModel(player: FavoritesCardView_Previews.player))
        .environmentObject(Favorites())
        .environmentObject(FavoritesCardView_Previews.player)
        
        //        .preferredColorScheme(.dark)
    }
}
