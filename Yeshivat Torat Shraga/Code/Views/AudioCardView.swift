//
//  AudioCardView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/22/21.
//

import SwiftUI

struct AudioCardView: View {
    @EnvironmentObject var favoritesManager: Favorites
    @ObservedObject var model: AudioCardModel
    @EnvironmentObject var audioPlayerModel: AudioPlayerModel
    @State var isShowingPlayerSheet = false
    let showAuthor: Bool
    
    init(audio: Audio, showAuthor: Bool = false) {
        self.model = AudioCardModel(audio: audio)
        self.showAuthor = showAuthor
    }
    
    var body: some View {
        Button {
            audioPlayerModel.play(audio: model.audio)
            isShowingPlayerSheet = true
        } label: {
            HStack {
                Rectangle()
                
                // START GRADIENT {
                
                    .fill(UI.cardBlueGradient)
                
                // } END GRADIENT
                
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
                                .font(.title3)
                                .bold()
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
        .shadow(radius: UI.shadowRadius)
        .sheet(isPresented: $isShowingPlayerSheet) {
            AudioPlayer()
                .environmentObject(audioPlayerModel)
                .environmentObject(favoritesManager)
        }
    }
}

struct AudioCardView_Previews: PreviewProvider {
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
            //            .background(Color.black)
        }
        .preferredColorScheme(.dark)
        .environmentObject(AudioPlayerModel(player: Player()))
        .environmentObject(Favorites())

    }
}
