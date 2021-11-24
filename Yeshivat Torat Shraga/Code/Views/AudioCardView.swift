//
//  AudioCardView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/22/21.
//

import SwiftUI

struct AudioCardView: View {
    @ObservedObject var model: AudioCardModel
    @State var isShowingPlayerSheet = false
    
    init(audio: Audio) {
        self.model = AudioCardModel(audio: audio)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(model.audio.name)
                    .font(.title)
                    .bold()
                Text(model.audio.author.name)
            }
            Spacer()
            VStack(alignment: .trailing) {
                HStack {
                    Text(timeFormattedMini(totalSeconds: model.audio.duration ?? 0))
                        .foregroundColor(Color("Gray"))
                    Image(systemName: "clock")
                }
                if let date = model.audio.date {
                    if let month = Date.monthNameFor(date.get(.month)) {
                        HStack {
                            let yearAsString = String(date.get(.year))
                            Text("\(month) \(date.get(.day)), \(yearAsString)")
                                .foregroundColor(Color("Gray"))
                            Image(systemName: "calendar")
                        }
                    }
                }
            }
            .padding()

            Button {
                RootModel.audioPlayer.set(audio: model.audio)
                isShowingPlayerSheet = true
            } label: {
                Image(systemName: "play.circle.fill")
                    .shadow(radius: 1)
                    .scaleEffect(2.25)
            }
        }
        .padding()
        .sheet(isPresented: $isShowingPlayerSheet) {
            RootModel.audioPlayer
        }
    }
}

struct AudioCardView_Previews: PreviewProvider {
    static var previews: some View {
        AudioCardView(audio: .sample)
            
            
    }
}
