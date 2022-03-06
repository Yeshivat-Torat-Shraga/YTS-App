//
//  HomeView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/11/21.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var model: HomeModel
    @AppStorage("lastViewedAlertID") var lastViewedAlertID = ""
    @State var presentingSearchView = false
    
    init(hideLoadingScreenClosure: @escaping (() -> Void),
         showErrorOnRoot: @escaping ((Error, (() -> Void)?) -> Void)) {
        self.model = HomeModel(hideLoadingScreen: hideLoadingScreenClosure,
                               showErrorOnRoot: showErrorOnRoot)
    }
    
    init() {
        self.model = HomeModel()
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack {
                    
                    // MARK: - Recently Uploaded
                    VStack(spacing: 0.0) {
                        HStack {
                            Text("Recently Uploaded")
                                .font(.title3)
                                .bold()
                            Spacer()
                        }
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
                        
                        Divider().padding(.horizontal)
                    }
                    
                    
                    // MARK: - Rebbeim
                    VStack(spacing: 0) {
                        HStack {
                            Text("Rebbeim")
                                .font(.title3)
                                .bold()
                            Spacer()
                        }.padding(.horizontal)
                        if let rebbeim = model.rebbeim {
                            if rebbeim.count < 1 {
                                Text("Either there is no content to show here, or our servers are experiencing an issue. Please try again soon.")
                                    .padding()
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(rebbeim, id: \.self) { rabbi in
                                            NavigationLink(destination: DisplayRabbiView(rabbi: rabbi)) {
                                                RabbiTileView(rabbi: rabbi, size: .medium)
                                            }
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
                        Divider().padding(.horizontal)
                    }
                    
                    // MARK: - SLIDESHOW
                    VStack(spacing: 0) {
                        HStack {
                            Text("Featured Photos")
                                .font(.title3)
                                .bold()
                            Spacer()
                        }
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
                        Divider().padding(.horizontal)
                    }
                    
                    // MARK: - CATEGORIES
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
                    }
                }
                .padding(.bottom)
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
