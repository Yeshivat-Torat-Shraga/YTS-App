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
        Button {
            RootModel.audioPlayer.play(audio: model.audio)
            isShowingPlayerSheet = true
        } label: {
            HStack {
                Rectangle()
                
                // START GRADIENT {
                
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
                
                // } END GRADIENT
                
                    .frame(width: 125)
                    .overlay(
                        Image(systemName: "mic")
                            .scaleEffect(1.35)
                            .foregroundColor(Color("ShragaGold"))
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
                        HStack {
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
                
                .padding()
            }
        }
        .buttonStyle(BackZStackButtonStyle())
        .frame(height: 105)
        .background(
            Rectangle()
                .fill(Color(UIColor.systemBackground))
                .cornerRadius(UI.cornerRadius)
                .shadow(radius: UI.shadowRadius)
        )
        .cornerRadius(UI.cornerRadius)
        .sheet(isPresented: $isShowingPlayerSheet) {
            RootModel.audioPlayer
        }
    }
}

struct AudioCardView_Previews: PreviewProvider {
//    static var previews: some View {
//        VStack {
//            AudioCardView(audio: .sample)
//            VideoCardView(video: .sample)
//            AudioCardView(audio: .sample)
//            VideoCardView(video: .sample)
//        }
//        .padding()
//        .foregroundColor(Color("ShragaBlue"))
//        .background(Color.black)
//
//    }
    static var previews: some View = VideoCardView_Previews.previews
        .preferredColorScheme(.dark)
}
