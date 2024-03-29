//
//  SearchedAudioCardView.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 11/11/22.
//

import SwiftUI
import FirebaseAnalytics

/// AudioCardView for general search, where the author name should be displayed
struct SearchedAudioCardView: View {
    @EnvironmentObject var favoritesManager: Favorites
    @EnvironmentObject var audioPlayerModel: AudioPlayerModel
    @EnvironmentObject var player: Player
    @ObservedObject var model: AudioCardModel
    @State private var isFavoritesBusy = false
    @State private var heartFillOverride = false
    @State var isShowingPlayerSheet = false
    let showAuthor: Bool
    
    init(audio: Audio, showAuthor: Bool = true) {
        self.model = AudioCardModel(audio: audio)
        self.showAuthor = showAuthor
    }
    
    var body: some View {
        Button {
            audioPlayerModel.play(audio: model.audio)
            isShowingPlayerSheet = true
            Analytics.logEvent("opened_content_card", parameters: [
                "type": "audio",
                "source": "audio_card",
                "content_creator": model.audio.author.name,
                "content_title": model.audio.title,
                "content_length": Int(model.audio.duration ?? 0),
            ])

        } label: {
            HStack {
                Rectangle()
                    .fill(UI.cardBlueGradient)
                    .frame(width: 125)
                    .overlay(
                        Image(systemName: "mic")
                            .scaleEffect(1.35)
                            .foregroundColor(Color("ShragaGold"))
                            .unredacted()
                    )
                    .foregroundColor(Color("ShragaGold"))
                
                // Rest of card goes here:
                VStack {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(model.audio.name)
                                .font(.headline)
                                .minimumScaleFactor(0.8)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                    }
                    Spacer()
                    HStack {
                        if showAuthor {
                            HStack {
                                Image(systemName: "person.fill")
                                Text("\(model.audio.author.name)")
                                    .truncationMode(.head)
                                    .foregroundColor(Color("Gray"))
                            }
                        } else {
                            if let date = model.audio.date {
                                if let month = Date.monthNameFor(date.get(.month), short: true) {
                                    HStack {
                                        let yearAsString = String(date.get(.year))
                                        Image(systemName: "calendar")
                                        Text("\(month) \(date.get(.day)), \(yearAsString)")
                                            .foregroundColor(Color("Gray"))
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                        
                        HStack {
                            Text(timeFormattedMini(totalSeconds: model.audio.duration ?? 0))
                                .foregroundColor(Color("Gray"))
                            Image(systemName: "clock")
                        }
                        .padding(.trailing, 5)
                    }
                    .font(.footnote)
                }
                
                .padding([.vertical, .trailing])
                .padding(.leading, 5)
            }
        }
        .buttonStyle(BackZStackButtonStyle(backgroundColor: .clear))
        .frame(height: 105)
        .background(
            Rectangle()
                .fill(Color.cardViewBG)
                .cornerRadius(UI.cornerRadius)
        )
        .cornerRadius(UI.cornerRadius)
        .contextMenu {
            if let audio = model.audio, let favoriteIDs = favoritesManager.favoriteIDs {
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
            }
            Button(action: {
                audioPlayerModel.play(audio: model.audio)
                isShowingPlayerSheet = true
            }) {
                Label("Play", systemImage: "play")
            }
        }
        .shadow(radius: UI.shadowRadius)
        .sheet(isPresented: $isShowingPlayerSheet) {
            AudioPlayer()
                .environmentObject(audioPlayerModel)
                .environmentObject(favoritesManager)
                .environmentObject(player)
        }
    }
}

struct SearchedAudioCardView_Previews: PreviewProvider {
    static var player = Player()
    static var previews: some View {
        ScrollView {
            VStack {
                AudioCardView(audio: .sample)
                VideoCardView(video: .sample)
                AudioCardView(audio: .sample)
                VideoCardView(video: .sample)
            }
            .padding()
            .foregroundColor(Color("ShragaBlue"))
        }
        .preferredColorScheme(.dark)
        .environmentObject(AudioPlayerModel(player: AudioCardView_Previews.player))
        .environmentObject(player)
        .environmentObject(Favorites())
        
    }
}
