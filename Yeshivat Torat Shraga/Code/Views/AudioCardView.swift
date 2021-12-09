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
        VStack {
            HStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(
                            stops: [
                                Gradient.Stop(
                                    color: Color(
                                        hue: 0.610,
                                        saturation: 0.5,
                                        brightness: 0.19),
                                    location: 0),
                                Gradient.Stop(
                                    color: Color(
                                        hue: 0.616,
                                        saturation: 0.431,
                                        brightness: 0.510),
                                    location: 1)]),
                        startPoint: UnitPoint.bottomLeading,
                        endPoint: UnitPoint.trailing))
                    .frame(width: 35, height: 35)
                    .overlay(
                        Image(systemName: "mic")
                            .foregroundColor(Color("ShragaGold"))
                    )
                VStack(alignment: .leading) {
                    Text(model.audio.name)
                        .font(.title3)
                        .bold()
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button {
                    RootModel.audioPlayer.play(audio: model.audio)
                    isShowingPlayerSheet = true
                } label: {
                    Image(systemName: "play.circle.fill")
                        .resizable()
                        .shadow(radius: 1)
                }
                .frame(width: 35, height: 35)
                .padding()
            }
            HStack {
                HStack {
                    if let date = model.audio.date {
                        if let month = Date.monthNameFor(date.get(.month)) {
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
        .padding()
        .background(Rectangle()
                        .fill(Color(UIColor.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 2)
        )
        
        
        .sheet(isPresented: $isShowingPlayerSheet) {
            RootModel.audioPlayer
        }
    }
}

struct AudioCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            AudioCardView(audio: .sample)
            AudioCardView(audio: .sample)
            AudioCardView(audio: .sample)
            AudioCardView(audio: .sample)
        }
        .padding()
        .foregroundColor(Color("ShragaBlue"))
        
    }
}
