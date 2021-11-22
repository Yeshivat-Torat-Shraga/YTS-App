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
            VStack {
                Text(model.audio.name)
                Text(model.audio.author.name)
                Button {
                    RootModel.audioPlayer.set(audio: model.audio)
                    isShowingPlayerSheet = true
                } label: {
                    Image(systemName: "play")
                }
            }
        }.sheet(isPresented: $isShowingPlayerSheet) {
            RootModel.audioPlayer
        }
    }
}

struct AudioCardView_Previews: PreviewProvider {
    static var previews: some View {
        AudioCardView(audio: .sample)
    }
}
