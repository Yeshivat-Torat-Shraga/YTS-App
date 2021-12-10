//
//  DisplayRabbiView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/16/21.
//

import SwiftUI

struct DisplayRabbiView: View {
    @ObservedObject var model: DisplayRabbiModel
    
    init(rabbi: DetailedRabbi) {
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
                .padding()
                Divider()
            }
            Group {
                HStack {
                    Text("Recently Uploaded")
                        .font(.title3)
                        .bold()
                    Spacer()
                }
                .padding(.horizontal)
                VStack {
//                    ScrollView(.vertical) {
//                    AudioCardView(audio: .sample)
                    if let audios = model.audios {
                        ForEach(audios, id: \.self) { audio in
                            AudioCardView(audio: audio)
                                .contextMenu {
                                    Button("Play") {
                                    }
                                }
                        }
                    } else {
                        ProgressView()
                    }
//                    }
//                    .padding()
//                    Spacer()
                    if let videos = model.videos {
                    ForEach(videos, id: \.self) { video in
                        VideoCardView(video: video)
                            .contextMenu {
                                Button("Play") {}
                            }
                    }
                    } else {
                        ProgressView()
                    }
                    
                }
                .padding(.horizontal)
            }
        }
        //        .padding(.horizontal)
        .navigationTitle(model.rabbi.name)
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    LogoView(size: .small)
                    DownloadableImage(object: model.rabbi)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .shadow(radius: 1)
                }
            }
        })
        .onAppear {
            self.model.load()
        }
    }
}

struct DisplayRabbiView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DisplayRabbiView(rabbi: DetailedRabbi.samples[2])
        }
    }
}
