//
//  SearchView.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 12/20/21.
//

import SwiftUI

struct SearchView: View {
    @ObservedObject var model = SearchModel()
    @State var selectedResultTag: SearchOptions = .all
    @State var showAlert = false
    @State var alertBody = ""
    @State var alertTitle = ""
    
    var body: some View {
        VStack {
            Group {
                SearchBar(search: model.newSearch)
                    .disableAutocorrection(true)
                
                Picker("Result Type", selection: $selectedResultTag) {
                    Text("All")
                        .tag(SearchOptions.all)
                    Text("Shiurim")
                        .tag(SearchOptions.shiurim)
                    Text("Rebbeim")
                        .tag(SearchOptions.rebbeim)
                }
                //                .onChange(of: selectedResultTag) { value in
                //                    withAnimation {
                //
                //                    }
                //                }
                .pickerStyle(SegmentedPickerStyle())
                .padding([.bottom])
            }
            .padding(.horizontal)
            
            ScrollView(showsIndicators: false) {
                LazyVStack {
                    if selectedResultTag == .rebbeim || selectedResultTag == .all {
                        Group {
                            if let rebbeim = model.rebbeim {
                                ForEach(rebbeim, id: \.self) { rabbi in
                                    if let detailedRabbi = rabbi as? DetailedRabbi {
                                        NavigationLink(destination: DisplayRabbiView(rabbi: detailedRabbi)) {
                                            RabbiCardView(rabbi: rabbi)
                                                .padding(.horizontal)
                                                .padding(.top, UI.shadowRadius)
                                        }
                                    }
                                }
                            }
                            
                            
                            if model.loadingRebbeim && !model.loadingContent {
                                ProgressView()
                                    .progressViewStyle(YTSProgressViewStyle())
                            } else if !model.loadingRebbeim && !model.loadingContent && model.calledInitialLoad && !model.retreivedAllRebbeim {
                                LoadMoreBar(action: {
                                    withAnimation {
                                        model.searchForMoreRebbeim()
                                    }
                                })
                                    .padding(.horizontal)
                            }
                            
                            if !model.loadingRebbeim && !model.retreivedAllRebbeim && !(model.rebbeim?.isEmpty ?? true) {
                                Divider()
                            }
                            
                        }
                        .padding(.bottom)
                    }
                    
                    
                    if selectedResultTag == .shiurim || selectedResultTag == .all {
                        Group {
                            if let sortables = model.sortables {
                                ForEach(sortables, id: \.self) { sortable in
                                    if let video = sortable.video {
                                        VideoCardView(video: video)
                                    } else if let audio = sortable.audio {
                                        AudioCardView(audio: audio)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            if model.loadingContent && !model.loadingRebbeim {
                                ProgressView()
                                    .progressViewStyle(YTSProgressViewStyle())
                            } else if !model.loadingContent && !model.loadingRebbeim && model.calledInitialLoad && !model.retreivedAllContent {
                                LoadMoreBar(action: {
                                    withAnimation {
                                        model.searchForMoreContent()
                                    }
                                }).padding(.horizontal)
                            }
                            
                            if !model.loadingContent && model.retreivedAllContent && !(model.contentIsEmpty) {
                                Divider()
                            }
                        }
                        .padding(.bottom)
                    }
                    
                    if model.loadingContent && model.loadingRebbeim {
                        ProgressView()
                            .progressViewStyle(YTSProgressViewStyle())
                    } else if !model.loadingContent && !model.loadingRebbeim && model.content?.videos.isEmpty ?? false && model.content?.audios.isEmpty ?? false && model.rebbeim?.isEmpty ?? false {
                        Text("Sorry, no results were found.")
                            .font(.title2)
                            .bold()
                        Spacer()
                        Text("Try searching with full words and names.")
                    }
                }
                .alert(isPresented: $showAlert, content: {
                    Alert(title: Text(alertTitle), message: Text(alertBody), dismissButton: Alert.Button.default(Text("OK")))
                })
                .navigationBarHidden(true)
            }
        }
        .animation(.default, value: selectedResultTag)
        .background(
            Blur(style: .systemThinMaterial).edgesIgnoringSafeArea(.vertical)
        )
    }
    
    enum SearchOptions: String {
        case all = "All"
        case shiurim = "Shiurim"
        case rebbeim = "Rebbeim"
    }
    
    struct SearchBar: View {
        @State var searchText: String = ""
        var search: (_ text: String) -> Void
        
        init(search: @escaping (_ text: String) -> Void) {
            self.search = search
        }
        
        var body: some View {
            ZStack {
                Rectangle()
                    .foregroundColor(Color("ShragaBlue"))
                    .opacity(0.1)
                
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("", text: $searchText, onCommit: {
                        search(searchText)
                    })
                        .placeholder(when: searchText.isEmpty) {
                            Text("Search")
                        }
                    
                }
                .padding(.leading, 13)
                
            }
            .frame(height: 40)
            .cornerRadius(13)
            .padding(.top)
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    struct binding: View {
        @State var presentingSearchView = true
        var body: some View {
            VStack {
                HStack {Spacer()}
                Spacer()
                Button(action: { presentingSearchView = true }) {
                    Text("Show Sheet")
                        .foregroundColor(Color("ShragaGold"))
                }
                .padding()
                .background(Color.blue)
                .cornerRadius(7)
                .shadow(radius: 3)
                Spacer()
            }
            .sheet(isPresented: $presentingSearchView) {
                NavigationView {
                    SearchView()
                }
            }
        }
    }
    static var previews: some View {
        binding()
    }
}
