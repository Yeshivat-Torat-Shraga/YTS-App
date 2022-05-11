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
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var favorites: Favorites
    
    let content: Content
    let isAudio: Bool
    
    init(content: Content) {
        self.content = content
        self.isAudio = (content.sortable.audio != nil)
    }
    var body: some View {
        Button(action: {
            if isAudio {
                RootModel.audioPlayer.play(audio: content.sortable.audio!)
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
        .background(Color.CardViewBG)
        .overlay(
            VStack {
                HStack {
                    Spacer()
                    Image(systemName: getFillState("bookmark"))
                        .foregroundColor(.shragaGold)
                        .padding(5)
                        .offset(y: -8)
                        .shadow(radius: 2)
                }
                Spacer()
            }
        )
        
        .cornerRadius(UI.cornerRadius)
        .clipped()
        .sheet(isPresented: $isShowingPlayerSheet) {
            RootModel.audioPlayer.environmentObject(favorites)
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
    static var previews: some View {
        ZStack {
            Color("FavoritesBG").ignoresSafeArea()
            VStack {
                SortableFavoritesCardView(content: SortableYTSContent(audio: Audio.sample))
                SortableFavoritesCardView(content: SortableYTSContent(audio: Audio.sample))
                SortableFavoritesCardView(content: SortableYTSContent(audio: Audio.sample))
                SortableFavoritesCardView(content: SortableYTSContent(audio: Audio.sample))
                SortableFavoritesCardView(content: SortableYTSContent(audio: Audio.sample))
                //                SortableFavoritesCardView(content: SortableYTSContent(video: Video.sample))
            }
            .shadow(radius: UI.shadowRadius)
            .padding(.horizontal)
        }
        //        .preferredColorScheme(.dark)
    }
}
