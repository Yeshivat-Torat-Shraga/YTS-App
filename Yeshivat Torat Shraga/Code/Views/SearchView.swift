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
            VStack {
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
            
            if model.sortables == nil && (!model.loadingContent && !model.loadingRebbeim) {
                    Text("Search for content on the app")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                    Spacer()
                    Text("Try using one or two words that are unique to what you're searching for.")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                Spacer()
            } else if (!model.loadingContent && !model.loadingRebbeim) && ((model.content?.videos.isEmpty ?? false && model.content?.audios.isEmpty ?? false && model.rebbeim?.isEmpty ?? false) || (selectedResultTag == .shiurim && model.content?.videos.isEmpty ?? false && model.content?.audios.isEmpty ?? false) || (selectedResultTag == .rebbeim && model.rebbeim?.isEmpty ?? false)) {
                Text("Sorry, no results were found.")
                    .font(.title2)
                    .bold()
                    .padding(.horizontal)
                Spacer()
                Text("Try searching with full words and names.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Spacer()
            } else if model.loadingContent && model.loadingRebbeim {
                ProgressView()
                    .progressViewStyle(YTSProgressViewStyle())
            }
            
            ScrollView(showsIndicators: false) {
                LazyVStack {
                    if selectedResultTag == .rebbeim || selectedResultTag == .all, let rebbeim = model.rebbeim, !rebbeim.isEmpty {
                        VStack {
                                ForEach(rebbeim, id: \.self) { rabbi in
                                    if let detailedRabbi = rabbi as? DetailedRabbi {
                                        Spacer()
                                        NavigationLink(destination: DisplayRabbiView(rabbi: detailedRabbi)) {
                                            RabbiCardView(rabbi: rabbi)
                                        }
                                        Spacer()
                                    }
                                }
                            
                            if model.loadingRebbeim && !model.loadingContent {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(YTSProgressViewStyle())
                            } else if !model.loadingRebbeim && model.calledInitialLoad && !model.retreivedAllRebbeim {
                                Spacer()
                                LoadMoreBar(action: {
                                    withAnimation {
                                        model.searchForMoreRebbeim()
                                    }
                                })
                            }
                            
//                            if !model.loadingRebbeim && !model.retreivedAllRebbeim && !(model.rebbeim?.isEmpty ?? true) {
//                                Divider()
//                            }
                        }
                        .padding(.bottom)
                    }
                    
                    if selectedResultTag == .shiurim || selectedResultTag == .all, let sortables = model.sortables, !sortables.isEmpty {
                        VStack {
                                ForEach(sortables, id: \.self) { sortable in
                                    if let video = sortable.video {
                                        Spacer()
                                        VideoCardView(video: video)
                                        Spacer()
                                    } else if let audio = sortable.audio {
                                        Spacer()
                                        AudioCardView(audio: audio)
                                        Spacer()
                                    }
                            }
                            
                            if model.loadingContent && !model.loadingRebbeim {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(YTSProgressViewStyle())
                            } else if !model.loadingContent && model.calledInitialLoad && !model.retreivedAllContent {
                                Spacer()
                                LoadMoreBar(action: {
                                    withAnimation {
                                        model.searchForMoreContent()
                                    }
                                })
                            }
                            
//                            if !model.loadingContent && model.retreivedAllContent && !(model.contentIsEmpty) {
//                                Divider()
//                            }
                        }
                        .padding(.bottom)
                    }
                }
                .padding(.horizontal)
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
                        .foregroundColor(.shragaBlue)
                }
            }
        }
    }
    static var previews: some View {
        binding()
    }
}
