//
//  ContentCardView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 02/02/2022.
//

import SwiftUI

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
    @Environment(\.colorScheme) var colorScheme
    @State var isShowingPlayerSheet = false
    let content: Content
    var isAudio: Bool {
        return content is Audio
    }
    
    init(content: Content) {
        self.content = content
    }
    
    var body: some View {
        Button(action: {
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
                    Blur(style: .systemUltraThinMaterial)
                } else {
                    // If the card is for Videos
                    DownloadableImage(object: content)
                    Blur(style: .systemUltraThinMaterial)
                }
                
                VStack {
                    HStack {
                        VStack {
                            HStack {
                                Text(content.title)
                                    .font(.title3)
                                    .bold()
                                    .lineLimit(2)
                                Spacer()
                            }
                            
                            HStack {
                                Text(content.author.name)
                                    .font(.callout)
                                Spacer()
                            }
                            
                            Spacer()
                        }
                        if let detailedRabbi = content.author as? DetailedRabbi {
                            VStack {
                                DownloadableImage(object: detailedRabbi)
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 40, height: 40)
                                    .background(Color("Gray"))
                                    .clipShape(Circle())
                                    .clipped()
                                    .shadow(radius: 2)
                                Spacer()
                            }
                        }
                    }
                    Spacer()
                    HStack {
                        if let month = Date.monthNameFor(content.date.get(.month)) {
                            let yearAsString = String(content.date.get(.year))
                            Text("\(month) \(content.date.get(.day)), \(yearAsString)")
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
                    }.font(.caption)
                }
                .padding()
                .clipped()
                
            }
            .foregroundColor(.primary)
            .frame(minWidth: 225)
            .frame(height: 125)
            .clipped()
            
            
        }
        .buttonStyle(BackZStackButtonStyle())
        .cornerRadius(UI.cornerRadius)
        .shadow(radius: UI.shadowRadius)
        .sheet(isPresented: $isShowingPlayerSheet) {
            AudioPlayer()
                .environmentObject(audioPlayerModel)
                .environmentObject(favoritesManager)
        }
    }
}

struct ContentCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ContentCardView(content: Audio.sample)
            ContentCardView(content: Video.sample)
        }
        .padding()
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.dark)
    }
}
