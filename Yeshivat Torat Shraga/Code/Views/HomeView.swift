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
    
    @State var presentingSearchView = false
    
    init() {
        self.model = HomeViewModel()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    VStack(spacing: 0.0) {
                        HStack {
                            Text("Recently Uploaded")
                                .font(.title3)
                                .bold()
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        if let sortables = model.sortables {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(sortables, id: \.self) { sortable in
                                        Group {
                                            if let audio = sortable.audio {
                                                AudioTile(audio: audio)
                                            } else if let video = sortable.video {
                                                VideoTile(video: video)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        } else {
                            ProgressView()
                                .padding(.bottom)
                        }
                        
                        Divider().padding(.horizontal)
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
                        Divider().padding()
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
                                    TagTileView(category)
                                        .padding(.vertical)
                                }
                            }.padding()
                        }
                        Divider().padding()
                    }
                }
                .padding(.bottom)
                .navigationTitle("Home")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 0.0) {
                        LogoView(size: .small)
                            EllipseButton(action: {
                                self.presentingSearchView = true
                            }, imageSystemName: "magnifyingglass", foregroundColor: .white, backgroundColor: Color("ShragaBlue"))
                        }
                    }
                }
            }.alert(isPresented: Binding(get: {
                model.showError
            }, set: {
                model.showError = $0
            }), content: {
                Alert(
                    title: Text("Error"),
                    message: Text(
                        model.errorToShow?.getUIDescription() ??
                        "An unknown error has occured."),
                    dismissButton: Alert.Button.default(
                        Text("Retry"),
                        action: {
                            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                                self.model.retry?()
                            }
                        }))
            })
        }
        .sheet(isPresented: $presentingSearchView) {
            SearchView()
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .foregroundColor(Color("ShragaBlue"))
            .accentColor(Color("ShragaBlue"))
    }
}
