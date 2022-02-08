//
//  FavoritesCardView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 06/02/2022.
//

import SwiftUI

struct SortableFavoritesCardView<Content: SortableYTSContent>: View {
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
    @State var isShowingPlayerSheet = false
    let content: Content
    let isAudio: Bool
    
    init(content: Content) {
        self.content = content
        self.isAudio = (content.sortable.audio != nil)
    }
    var body: some View {
        let cornerSize: CGFloat = 65
        Button(action: {
            if isAudio {
                RootModel.audioPlayer.play(audio: content.sortable.audio!)
                isShowingPlayerSheet = true
            } else {
                //                 Video Player goes here
            }
        }) {
            HStack(alignment: .center) {
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
                
                VStack(alignment: .leading) {
                    Text(content.title)
                        .font(.title3)
                        .bold()
                        .foregroundColor(Color("ShragaBlue"))
                    Text(content.author.name)
                    //                    .foregroundColor(.black)
                    HStack {
                        Text(timeFormattedMini(totalSeconds: content.duration ?? 0))
                        Image(systemName: "clock")
                    }
                    .font(.subheadline)
                    .foregroundColor(Color("Gray"))
                }
                //            .padding(.top, 7)
                Spacer()
            }
        }
        //        .padding(.vertical)
        .background(Color("FavoritesFG"))
        .overlay(
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Rectangle()
                        .fill(Color("ShragaBlue"))
                        .rotationEffect(.degrees(45))
                        .offset(x: cornerSize/2, y: cornerSize/2)
                        .frame(width: cornerSize, height: cornerSize)
                        .overlay(
                            Image(systemName: isAudio
                                  ? "mic"
                                  : "play.rectangle")
                                .foregroundColor(Color("ShragaGold"))
                                .offset(
                                    x: cornerSize/3.25 + (isAudio
                                                          ? 0 : -1),
                                    y: cornerSize/3.25 + (isAudio
                                                          ? -2 : 0))
                        )
                }
            }
        )
        .cornerRadius(UI.cornerRadius)
        .clipped()
        .sheet(isPresented: $isShowingPlayerSheet) {
            RootModel.audioPlayer
        }
    }
}

struct FavoritesCardView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color("FavoritesBG").ignoresSafeArea()
            VStack {
                SortableFavoritesCardView(content: SortableYTSContent(audio: Audio.sample))
                SortableFavoritesCardView(content: SortableYTSContent(video: Video.sample))
            }
            .shadow(radius: UI.shadowRadius)
            .padding(.horizontal)
        }
    }
}
