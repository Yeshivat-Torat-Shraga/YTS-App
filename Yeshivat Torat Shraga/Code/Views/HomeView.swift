//
//  HomeView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/11/21.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var model: HomeViewModel
    
    init(rebbeim: [DetailedRabbi]) {
        self.model = HomeViewModel(rebbeim: rebbeim)
    }
    
    init() {
        self.model = HomeViewModel()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    HStack {
                        Text("Recently Uploaded")
                        Spacer()
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
//                        ForEach(model.recentlyUploaded, id: \.self) { content in
//                            NavigationLink(destination: Text("Recently uploaded content object")) {
//                                TileCardView(content: content, size: .wide)
//                            }
//                        }
                    }
                    Divider()
                    HStack {
                        Text("Rebbeim")
                        Spacer()
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(model.rebbeim ?? [], id: \.self) { rabbi in
                                NavigationLink(destination: DisplayRabbiView(rabbi: rabbi)) {
                                    TileCardView<DetailedRabbi>(content: rabbi, size: .small)
                                }
                                
                            }
                        }
                    }
                    Divider()
                }
                .padding()
                .navigationTitle("Welcome to YTS")
                .toolbar {
                    LogoView()
                }
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
