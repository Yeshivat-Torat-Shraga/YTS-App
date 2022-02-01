//
//  FavoritesView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 10/12/2021.
//

import SwiftUI

struct FavoritesView: View {
    @ObservedObject var model = FavoritesModel()
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    
                    // MARK: Audio Favorites
                    HStack {
                        Text("Audio")
                            .font(.title3)
                            .bold()
                        Spacer()
                    }
                    .padding(.horizontal)
                    if let audios = model.audios {
                        ScrollView(showsIndicators: false) {
                            HStack {
                                ForEach(audios, id: \.self) { audio in
                                    AudioCardView(audio: audio)
                                        .padding(.vertical)
                                }
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        VStack {
                            Text("It seems like you don't have any saved audio shiurim right now.")
                        }
                        .padding()
                    }
                    
                    // MARK: Video Favorites
                    HStack {
                        Text("Videos")
                            .font(.title3)
                            .bold()
                        Spacer()
                    }
                    .padding(.horizontal)
                    if let videos = model.videos {
                        ScrollView(showsIndicators: false) {
                            HStack {
                                ForEach(videos, id: \.self) { video in
                                    VideoCardView(video: video)
                                        .padding(.vertical)
                                }
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        VStack {
                            Text("It seems like you don't have any saved video shiurim right now.")
                        }
                        .padding()
                    }
                    
                    // MARK: Rebbeim Favorites
                    HStack {
                        Text("Rebbeim")
                            .font(.title3)
                            .bold()
                        Spacer()
                    }
                    .padding(.horizontal)
                    if let rebbeim = model.rebbeim {
                        ScrollView(showsIndicators: false) {
                            HStack {
                                ForEach(rebbeim, id: \.self) { rebbi in
                                    TileCardView(content: rebbi, size: .medium)
                                        .padding(.vertical)
                                }
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        VStack {
                            Text("It seems like you don't have any favorite rebbeim right now.")
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("Favorites")
    }
}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesView()
    }
}
