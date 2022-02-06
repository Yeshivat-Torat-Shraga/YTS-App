//
//  FavoritesView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 10/12/2021.
//

import SwiftUI

struct FavoritesView: View {
    @ObservedObject var model = FavoritesModel()
    @ObservedObject var f = Favorites.shared
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    
                    // MARK: Audio Favorites
                    HStack {
                        Text("Shiurim")
                            .font(.title3)
                            .bold()
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    if let sortables = model.sortables {
                        if sortables.count > 0 {
                            ScrollView(showsIndicators: false) {
                                    ForEach(sortables, id: \.self) { sortable in
                                        SortableFavoritesCardView(content: sortable)
                                            .shadow(radius: UI.shadowRadius)
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, UI.shadowRadius)
                            }
                        } else {
                            Text("It seems like you don't have any saved content right now.")
                        }
                    } else {
                        VStack {
                            Text("We're loading your favorites, hang tight....")
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
                        if rebbeim.count > 0 {
                            ScrollView(showsIndicators: false) {
                                HStack {
                                    ForEach(rebbeim, id: \.self) { rebbi in
                                        RabbiTileView(rabbi: rebbi, size: .medium)
                                            .shadow(radius: UI.shadowRadius)
                                            .padding(.vertical)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        } else {
                            Text("It seems like you don't have any saved rebbeim right now.")
                        }
                    } else {
                        VStack {
                            Text("We're loading your favorites, hang tight...")
                        }
                        .padding()
                    }
                }
            }
            .background(Color(hex: 0xF2F2F7).ignoresSafeArea())
            .navigationTitle("Favorites")
        }
        .onAppear {
            model.load()
        }
    }
}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
            FavoritesView()
                .foregroundColor(Color("ShragaBlue"))
    }
}
