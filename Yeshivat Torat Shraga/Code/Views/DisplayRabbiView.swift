//
//  DisplayRabbiView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/16/21.
//

import SwiftUI

struct DisplayRabbiView: View {
    @ObservedObject var model: DisplayRabbiModel
    
    init (rabbi: Rabbi) {
        model = DisplayRabbiModel(rabbi: rabbi)
    }
    
    var body: some View {
        ScrollView {
            Group {
                HStack {
                    Text("Favorites")
                        .font(.title3)
                        .bold()
                    Spacer()
                }
                Divider()
            }
            Group {
                HStack {
                    Text("Recently Uploaded")
                        .font(.title3)
                        .bold()
                    Spacer()
                }
                VStack {
                    ScrollView(.vertical) {
                        ForEach(model.audios ?? [], id: \.self) { audio in
                            AudioCardView(audio: audio)
                        }
                    }
                    Spacer()
                }
            }
        }
        .padding()
        .navigationTitle(model.rabbi.name)
        .toolbar(content: {
            LogoView(size: .small)
        })
    }
}

struct DisplayRabbiView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DisplayRabbiView(rabbi: DetailedRabbi.samples[0])
        }
    }
}
