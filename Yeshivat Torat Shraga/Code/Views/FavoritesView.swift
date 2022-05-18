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
    @State var presentingSearchView = false
    
    var miniPlayerShowing: Binding<Bool>
    
    init(miniPlayerShowing: Binding<Bool>) {
        self.miniPlayerShowing = miniPlayerShowing
    }
    
    var body: some View {
        NavigationView {
            ZStack {
//                Color.favoritesBG.ignoresSafeArea()
                ScrollView {
                    LazyVStack {
                        if let favorites = model.sortables {
                            if favorites.isEmpty {
                                HStack {
                                    Spacer()
                                    
                                    VStack {
                                        Text("Sorry, no favorite shiurim found.")
                                            .bold()
                                            .font(.title3)
                                            .padding(.bottom, 3)
                                        
                                        Spacer()
                                        
                                        Text("Press the 💛 while playing a shiur to add it to this list.")
                                            .font(.subheadline)
                                    }
                                    .multilineTextAlignment(.center)
                                    .padding()
                                    
                                    Spacer()
                                }
                                .background(Color(UIColor.systemGray4))
                                .cornerRadius(UI.cornerRadius)
                                .shadow(radius: UI.shadowRadius)
                            } else {
                                ForEach(Array(favorites.keys.sorted { lhs, rhs in
                                    lhs.name < rhs.name
                                }), id: \.self) { rabbi in
                                    if let contentArray = favorites[rabbi] {
                                        VStack(spacing: 6) {
                                            HStack {
                                                Text(rabbi.name)
                                                    .font(Font.callout)
                                                    .bold()
                                                Spacer()
                                            }
                                            
                                            ForEach(contentArray, id: \.self) { sortable in
                                                SortableFavoriteCardView(content: sortable)
                                                    .shadow(radius: UI.shadowRadius)
                                            }
                                            
                                            Divider()
                                                .padding(.bottom, 5)
                                                .padding(.vertical, UI.shadowRadius)
                                        }
                                    }
                                }
                            }
                        } else {
                            VStack {
                                Text("We're loading your favorites, hang tight....")
                            }
                            .padding()
                        }
                        
                        if miniPlayerShowing.wrappedValue {
                            Spacer().frame(height: UI.playerBarHeight)
                        }
                    }
                    .padding(.horizontal)
                } // ScrollView
            } // ZStack
            .navigationTitle("Favorites")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    LogoView(size: .small)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        self.presentingSearchView = true
                    }) {
                        Image(systemName: "magnifyingglass").foregroundColor(.shragaBlue)
                    }
                }
            }
            .onAppear {
                model.initialLoad(favorites: favorites)
            }
            .onChange(of: self.favorites.favoriteIDs) { _ in
                model.load(favorites: favorites)
            }
        }
        .sheet(isPresented: $presentingSearchView) {
            NavigationView {
                SearchView()
                    .background(BackgroundClearView())
            }
        }
    }
}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesView(miniPlayerShowing: .constant(false))
            .foregroundColor(.shragaBlue)
            .environmentObject(AudioPlayerModel(player: Player()))
            .environmentObject(Player())
            .environmentObject(Favorites())
    }
}
