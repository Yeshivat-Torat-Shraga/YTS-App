//
//  FavoritesView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 10/12/2021.
//

import SwiftUI

struct FavoritesView: View {
    @ObservedObject var model = FavoritesModel()
    @ObservedObject var favorites = Favorites.shared
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    if let favorites = model.sortables {
                        ForEach(Array(favorites.keys.sorted { lhs, rhs in
                            lhs.name < rhs.name
                        }), id: \.self) { rabbi in
                            HStack {
                                Text(rabbi.name)
                                    .bold()
                                    .font(.title3)
                                Spacer()
                            }
                            .padding(.top)
                            .padding(.horizontal)
                            
                            if let contentArray = favorites[rabbi] {
                                Group {
                                    ForEach(contentArray, id: \.self) { sortable in
                                        SortableFavoritesCardView(content: sortable)
                                            .shadow(radius: UI.shadowRadius)
                                    }
                                    Divider()
                                }
                                    .padding(.horizontal)
                                    .padding(.vertical, UI.shadowRadius)
                            }
                        }
                    } else {
                        VStack {
                            Text("We're loading your favorites, hang tight....")
                        }
                        .padding()
                    }
                }
                .padding(.bottom)
            }
            .background(Color("FavoritesBG").ignoresSafeArea())
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
            .foregroundColor(.shragaBlue)
    }
}
