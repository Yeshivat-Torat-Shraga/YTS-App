//
//  ContentCardView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 02/02/2022.
//

import SwiftUI
import FirebaseAnalytics

struct SortableContentCardView<Content: SortableYTSContent>: View {
    let content: Content
    
    var body: some View {
        if let audio = content.audio {
            ContentCardView(content: audio)
        } else if let video = content.video {
            ContentCardView(content: video)
        }
    }
}

struct ContentCardView<Content: YTSContent>: View {
    @EnvironmentObject var favoritesManager: Favorites
    @EnvironmentObject var audioPlayerModel: AudioPlayerModel
    @EnvironmentObject var player: Player
    @Environment(\.colorScheme) var colorScheme
    @State var isShowingPlayerSheet = false
    @State private var isFavoritesBusy = false
    @State private var heartFillOverride = false
    let content: Content
    var isAudio: Bool {
        return content is Audio
    }
    
    init(content: Content) {
        self.content = content
    }
    
    var body: some View {
        Button(action: {
            Analytics.logEvent("tapped_recently_uploaded", parameters: [
                "content_creator": content.author.name,
                "content_title": content.title,
                "content_length": content.description,
            ])
            if isAudio {
                audioPlayerModel.play(audio: content.sortable.audio!)
                isShowingPlayerSheet = true
            } else {
                //                 Video Player goes here
            }
        }) {
            ZStack {
                if isAudio {
                    // If the card is for Audios
                    UI.cardBlueGradient
                } else {
                    // If the card is for Videos
                    DownloadableImage(object: content)
                }
                Blur(style: .systemUltraThinMaterial)
                    .overlay(Rectangle().fill(colorScheme == .light
                                              ? Color.white
                                              : Color.black).opacity(0.2))
                
                VStack {
                    HStack {
                        VStack {
                        HStack {
                            Text(content.title)
                                .font(.headline)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                        }
                        .padding(.top, 5)
                            Spacer()
                        }
                        
                        if let detailedRabbi = content.author as? DetailedRabbi {
                            Spacer()
                            Spacer()
                            
                            VStack {
                                DownloadableImage(object: detailedRabbi)
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 45, height: 45)
                                    .background(Color("Gray"))
                                    .clipShape(Circle())
                                    .clipped()
                                    .shadow(radius: UI.shadowRadius)
                                Spacer()
                            }
                        }
                    }
//                    .frame(height: 200)
                    
                    Spacer()
                    
                    HStack {
                        Text(content.author.name)
                            .font(.subheadline)
                        Spacer()
                    }
                    
                    Spacer()
                    
                    HStack {
                        if let month = Date.monthNameFor(content.date.get(.month)) {
                            let yearAsString = String(content.date.get(.year))
                            Text("\(month) \(content.date.get(.day)), \(yearAsString)")
                                .italic()
                        }
                        
                        Spacer()
                        
                        if let duration = content.duration {
                            HStack(spacing: 4) {
                                Image(systemName: isAudio
                                      ? "mic"
                                      : "play.rectangle.fill")
                                Text(timeFormattedMini(totalSeconds: duration))
                            }
                        }
                    }
                    .font(.caption)
                }
                .padding()
                .clipped()
            }
            .foregroundColor(.primary)
            .frame(minWidth: 225)
            .frame(maxWidth: 350)
            .frame(height: 115)
            .clipped()
        }
        .buttonStyle(BackZStackButtonStyle())
        .cornerRadius(UI.cornerRadius)
        .sheet(isPresented: $isShowingPlayerSheet) {
            AudioPlayer()
                .environmentObject(audioPlayerModel)
                .environmentObject(favoritesManager)
                .environmentObject(player)
        }
        .contextMenu {
            if let audio = content.sortable.audio, let favoriteIDs = favoritesManager.favoriteIDs {
                Button(action: {
                    if !isFavoritesBusy {
                        heartFillOverride = false
                        isFavoritesBusy = true
                        if favoriteIDs.contains(audio.firestoreID) {
                            self.favoritesManager.delete(audio) { favorites, error in
                                isFavoritesBusy = false
                            }
                        } else {
                            heartFillOverride = true
                            self.favoritesManager.save(audio) { favorites, error in
                                isFavoritesBusy = false
                            }
                        }
                    }
                }) {
                    Label(isFavoritesBusy
                          ? heartFillOverride
                              ? "heart.fill"
                              : "heart"

                          : favoriteIDs.contains(audio.firestoreID)
                              ? "Unfavorite"
                              : "Favorite",
                          
                          systemImage: isFavoritesBusy
                          ? heartFillOverride
                              ? "heart.fill"
                              : "heart"
                      
                          : favoriteIDs.contains(audio.firestoreID)
                              ? "heart.fill"
                              : "heart")
                }
                Button(action: {
                    audioPlayerModel.play(audio: audio)
                    isShowingPlayerSheet = true
                }) {
                    Label("Play", systemImage: "play")
                }
            }
        }
        .shadow(radius: UI.shadowRadius)
    }
}

struct ContentCardView_Previews: PreviewProvider {
    static var player = Player()
    static var previews: some View {
        VStack {
            ContentCardView(content: Audio.sample)
            ContentCardView(content: Video.sample)
        }
        .padding()
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.dark)
        .environmentObject(ContentCardView_Previews.player)
        .environmentObject(AudioPlayerModel(player: ContentCardView_Previews.player))
        .environmentObject(Favorites())
    }
}
