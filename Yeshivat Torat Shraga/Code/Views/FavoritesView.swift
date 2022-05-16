//
//  FavoritesView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 10/12/2021.
//

import SwiftUI

struct FavoritesView: View {
    @ObservedObject var model = FavoritesModel()
    @EnvironmentObject var favorites: Favorites
    @EnvironmentObject var audioPlayerModel: AudioPlayerModel
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.favoritesBG.ignoresSafeArea()
                ScrollView {
                    VStack {
                        if let favorites = model.sortables {
                            if favorites.isEmpty {
                                VStack {
                                    Text("No favorites found.")
                                        .bold()
                                        .font(.title2)
                                        .padding(.bottom, 3)
                                    Text("Press the ❤ while playing a shiur to add it to this list.")
                                }
                                .multilineTextAlignment(.center)
                                .padding()
                            } else {
                                ForEach(Array(favorites.keys.sorted { lhs, rhs in
                                    lhs.name < rhs.name
                                }), id: \.self) { rabbi in
                                    HStack {
                                        Text(rabbi.name)
                                            .bold()
                                            .font(.title3)
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    
                                    if let contentArray = favorites[rabbi] {
                                        Group {
                                            ForEach(contentArray, id: \.self) { sortable in
                                                SortableFavoriteCardView(content: sortable)
                                                    .shadow(radius: UI.shadowRadius)
                                            }
                                            Divider()
                                                .padding(.bottom, 5)
                                        }
                                        .padding(.horizontal)
                                        .padding(.vertical, UI.shadowRadius)
                                    }
                                }
                            }
                        } else {
                            VStack {
                                Text("We're loading your favorites, hang tight....")
                            }
                            .padding()
                        }
                        
                        if audioPlayerModel.audio != nil {
                            Spacer().frame(height: UI.playerBarHeight)
                        }
                    }
                    .padding(.bottom)
                } // ScrollView
            } // ZStack
            .navigationTitle("Favorites")
            .onAppear {
                model.initialLoad(favorites: favorites)
            }
            .onChange(of: self.favorites.favoriteIDs) { _ in
                model.load(favorites: favorites)
            }
        }
    }
}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesView()
            .foregroundColor(.shragaBlue)
            .environmentObject(AudioPlayerModel(player: Player()))
            .environmentObject(Player())
            .environmentObject(Favorites())
    }
}
