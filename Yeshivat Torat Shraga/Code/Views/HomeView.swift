//
//  HomeView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/11/21.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var model: HomeModel
//    @EnvironmentObject var player: Player
//    @EnvironmentObject var audioPlayerModel: AudioPlayerModel
//    @EnvironmentObject var favoritesManager: Favorites
    @AppStorage("lastViewedAlertID") var lastViewedAlertID = ""
    @State var presentingSearchView = false
    @State var searchView = SearchView()
    var miniPlayerShowing: Binding<Bool>
    
    init(hideLoadingScreen: @escaping (() -> Void),
         showErrorOnRoot: @escaping ((Error, (() -> Void)?) -> Void),
         miniPlayerShowing: Binding<Bool>) {
        self.model = HomeModel(hideLoadingScreen: hideLoadingScreen,
                               showErrorOnRoot: showErrorOnRoot)
        self.miniPlayerShowing = miniPlayerShowing
    }
    
    init(miniPlayerShowing: Binding<Bool>) {
        self.model = HomeModel()
        self.miniPlayerShowing = miniPlayerShowing
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack {
                    
                    // MARK: - Recently Uploaded
                    VStack(spacing: 0.0) {
                        LabeledDivider(title: "Recently Uploaded")
                            .padding(.horizontal)
                        
                        if let sortables = model.sortables {
                            if sortables.count < 1 {
                                Text("Either there is no content to show here, or our servers are experiencing an issue. Please try again soon.")
                                    .padding()
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(sortables, id: \.self) { sortable in
                                            SortableContentCardView(content: sortable)
                                                .padding(.vertical)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        } else {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(YTSProgressViewStyle())
                                Spacer()
                            }.padding()
                        }
                    }
                    
                    
                    // MARK: - Rebbeim
                    VStack(spacing: 0) {
                        LabeledDivider(title: "Rebbeim")
                            .padding(.horizontal)
                        if let rebbeim = model.rebbeim {
                            if rebbeim.count < 1 {
                                Text("Either there is no content to show here, or our servers are experiencing an issue. Please try again soon.")
                                    .padding()
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(rebbeim, id: \.self) { rabbi in
                                                RabbiTileView(rabbi: rabbi, size: .medium)
                                            .simultaneousGesture(
                                                TapGesture()
                                                    .onEnded {
                                                        Haptics.shared.play(UI.Haptics.navLink)
                                                    })
                                            .padding(.vertical)
                                        }
                                    }.padding(.horizontal)
                                }
                            }
                        } else {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(YTSProgressViewStyle())
                                Spacer()
                            }.padding()
                        }
                    }
                    
                    // MARK: - CATEGORIES
                    VStack(spacing: 0) {
                        LabeledDivider(title: "Categories")
                            .padding(.horizontal)
                        
                        if let tags = model.tags {
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack {
                                    ForEach(tags, id: \.name) { tag in
                                        TagTileView(tag)
                                            .padding(.vertical)
                                            .simultaneousGesture(
                                                TapGesture()
                                                    .onEnded {
                                                        Haptics.shared.play(UI.Haptics.navLink)
                                                    })
                                        
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
                    }

                    
                    // MARK: - SLIDESHOW
                    VStack(spacing: 0) {
                        LabeledDivider(title: "Featured Photos")
                            .padding(.horizontal)
                        if let slideshowImages = model.slideshowImages {
                            if slideshowImages.count < 1 {
                                Text("Either there is no content to show here, or our servers are experiencing an issue. Please try again soon.")
                                    .padding()
                            } else {
                                SlideshowView(slideshowImages)
                                    .frame(height: 250)
                                    .clipped()
                                    .cornerRadius(UI.cornerRadius)
                                    .shadow(radius: UI.shadowRadius)
                                    .padding()
                            }
                        } else {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(YTSProgressViewStyle())
                                Spacer()
                            }.padding()
                        }
                    }
                    
                    if miniPlayerShowing.wrappedValue {
                        Spacer().frame(height: UI.playerBarHeight)
                    }
                }
                .navigationTitle("Home")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        LogoView(size: .small)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {self.presentingSearchView = true}) {
                            Image(systemName: "magnifyingglass").foregroundColor(.shragaBlue)
                        }
                    }
                }
            }.alert(isPresented: $model.showError, content: {
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
                .onChange(of: model.showError) { errVal in
                    if (errVal){
                        Haptics.shared.notify(.error)
                    }
                }
        }
        .alert(isPresented: $model.showAlert) {
            Alert(title: Text(model.homePageAlertToShow!.title), message: Text(model.homePageAlertToShow!.body),
                  dismissButton: .cancel(Text("OK")) {
                lastViewedAlertID = model.homePageAlertToShow!.id
            })
        }
        .sheet(isPresented: $presentingSearchView) {
            NavigationView {
                searchView
//                    .environmentObject(player)
//                    .environmentObject(audioPlayerModel)
//                    .environmentObject(favoritesManager)
                // .envObjs should be here
                    .background(BackgroundClearView())
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(miniPlayerShowing: .constant(false))
            .environmentObject(Favorites())
            .environmentObject(AudioPlayerModel(player: Player()))
            .foregroundColor(Color("ShragaBlue"))
            .accentColor(Color("ShragaBlue"))
    }
}

struct LabeledDivider: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.title3)
                .bold()
                .layoutPriority(1)
            VStack {
                Divider()
            }
        }
    }
}
