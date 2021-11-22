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
    
    init(audioContent: Audio) {
        self.model = AudioCardModel(audioContent: audioContent)
    }
    
    var body: some View {
        HStack {
            VStack {
                Text(model.audio.name)
                Text(model.audio.author.name)
                
            }
        }
        .sheet(isPresented: $isShowingPlayerSheet) {
            AudioPlayer()
        }
    }
}

struct AudioCardView_Previews: PreviewProvider {
    static var previews: some View {
        AudioCardView(audioContent: .sample)
    }
}
