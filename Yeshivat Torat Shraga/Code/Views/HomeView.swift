//
//  HomeView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/11/21.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var model: HomeViewModel
    let categories: [Tag] = [Category(name: "Parsha", icon: Image("parsha")), Category(name: "Chanuka", icon: Image("chanuka")), Tag("Mussar"), Tag("Purim")]
    
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
                    Group {
                        HStack {
                            Text("Recently Uploaded")
                                .font(.title3)
                                .bold()
                            Spacer()
                        }
                        .padding(.horizontal)
                        
//                        ScrollView(.horizontal, showsIndicators: false) {
//                            //                        ForEach(model.recentlyUploaded, id: \.self) { content in
//                            //                            NavigationLink(destination: Text("Recently uploaded content object")) {
//                            //                                TileCardView(content: content, size: .wide)
//                            //                            }
//                            //                        }
//                        }
                        Divider()
                    }
                    
                    VStack(spacing: 0) {
                        HStack {
                            Text("Rebbeim")
                                .font(.title3)
                                .bold()
                            Spacer()
                        }.padding(.horizontal)
                        if let rebbeim = model.rebbeim {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(rebbeim, id: \.self) { rabbi in
                                        NavigationLink(destination: DisplayRabbiView(rabbi: rabbi)) {
                                            TileCardView<DetailedRabbi>(content: rabbi, size: .medium)
                                        }.padding(.vertical)
                                    }
                                }.padding(.horizontal)
                            }
                        } else {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(YTSProgressViewStyle())
                                Spacer()
                            }.padding()
                        }
                        Divider()
                    }
                    
                    VStack(spacing: 0) {
                        HStack {
                            Text("Categories")
                                .font(.title3)
                                .bold()
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack {
                                ForEach(categories, id: \.self) { category in
                                    TagView(category)
                                        .padding(.vertical)
                                }
                            }.padding(.horizontal)
                        }
                        Divider()
                    }
                }
                .padding(.vertical)
                .navigationTitle("Welcome to Shraga")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        LogoView(size: .small)
                        
                    }
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
