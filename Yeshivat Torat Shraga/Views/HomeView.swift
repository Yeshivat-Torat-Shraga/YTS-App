//
//  HomeView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/11/21.
//

import SwiftUI

struct HomeView: View {
    @StateObject var model: HomeViewModel = HomeViewModel()
    var body: some View {
        NavigationView {
            VStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(model.rabbis, id: \.self) { rabbi in
                            NavigationLink(destination: Text("surprise!")) {
                                TileCardView<Rabbi>(content: rabbi, size: .small)
                            }
                            
                        }
                    }
                }
            }
            .navigationTitle("This is YTS")
            .toolbar {
                Text("LOGO HERE")
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
