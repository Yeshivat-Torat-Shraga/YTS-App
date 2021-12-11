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
    
    init() {
        self.model = HomeViewModel()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    VStack {
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
                                ForEach(sortables.sorted(by: { lhs, rhs in
                                    lhs.date > rhs.date
                                }), id: \.firestoreID) { sortable in
                                    Group {
                                        if let audio = model.recentlyUploadedContent?.audios.first(where: { a in
                                            a.firestoreID == sortable.firestoreID
                                        }) {
                                            AudioTile(audio: audio)
                                                .frame(width: 300, height: 170)
                                        } else if let video = model.recentlyUploadedContent?.videos.first(where: { v in
                                            v.firestoreID == sortable.firestoreID
                                        }) {
                                            Text(video.title)
                                        } else {
                                            Text("Can't find the id")
                                        }
                                    }
                                }
                                }
                            }
                        } else {
                            ProgressView()
                        }
                        
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
            }.alert(isPresented: Binding(get: {
                model.showError
            }, set: {
                model.showError = $0
            }), content: {
                Alert(title: Text("Error"), message: Text(model.errorToShow?.getUIDescription() ?? "An unknown error has occured."), dismissButton: Alert.Button.default(Text("Retry"), action: {
                    Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                        self.model.retry?()
                    }
                }))
            })
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
