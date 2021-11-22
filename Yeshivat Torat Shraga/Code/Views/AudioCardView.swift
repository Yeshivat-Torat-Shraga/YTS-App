//
//  AudioCardView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/22/21.
//

import SwiftUI

struct AudioCardView: View {
    @ObservedObject var model: AudioCardModel
    
    init(audioContent: Audio) {
        self.model = AudioCardModel(audioContent: audioContent)
    }
    
    var body: some View {
        HStack {
            Text(model.audio.name)
        }
    }
}

struct AudioCardView_Previews: PreviewProvider {
    static var previews: some View {
        AudioCardView(audioContent: .sample)
    }
}
