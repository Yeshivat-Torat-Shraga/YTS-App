//
//  SearchView.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 12/20/21.
//

import SwiftUI

struct SearchView: View {
    @ObservedObject var model = SearchModel()
    @State var selectedResultTag = "Rebbeim"
    @State var searchText = ""
    @State var showAlert = false
    @State var alertBody = ""
    @State var alertTitle = ""
    var body: some View {
        NavigationView {
            ScrollView {
                ZStack {
                    Rectangle()

                        .foregroundColor(Color("ShragaBlue"))
                        .opacity(0.1)
                    HStack {
                        Image(systemName: "magnifyingglass")
                        TextField("", text: $searchText, onCommit: {
                            model.search(searchText)
                        })
                            .placeholder(when: searchText.isEmpty) {
                                Text("Search...")
//                                    .foregroundColor(Color("ShragaGold"))
                            }
                        
                    }
                    .foregroundColor(Color("ShragaGold"))
                    .padding(.leading, 13)
                    
                }
                .frame(height: 40)
                .cornerRadius(13)
                .padding([.top, .horizontal])
                
                Picker("Result Type", selection: $selectedResultTag) {
                    Text("Rebbeim")
                        .tag("Rebbeim")
                    Text("All")
                        .tag("All")
                    Text("Shiurim")
                        .tag("Shiurim")
                }
//                .onChange(of: selectedResultTag) { value in
//                    withAnimation {
//
//                    }
//                }
                .pickerStyle(SegmentedPickerStyle())
                .padding([.horizontal, .bottom])
                
                
                Text(selectedResultTag)
                    .background(Color.black)
                
                if selectedResultTag == "Rebbeim" || selectedResultTag == "All" {
                    if let rebbeim = model.rebbeim {
                        ForEach(rebbeim, id: \.self) { rabbi in
                            if let detailedRabbi = rabbi as? DetailedRabbi {
                                NavigationLink(destination: DisplayRabbiView(rabbi: detailedRabbi)) {
                                    RabbiCardView(rabbi: rabbi)
                                        .padding([.horizontal, .bottom])
                                }
                            } else {
                                Button(action: {
                                    alertTitle = "Oops!"
                                    alertBody = "Sorry, but \(rabbi.name)'s entry is missing the necessary information to show you their page. Please try again later."
                                    showAlert = true
                                }){
                                    RabbiCardView(rabbi: rabbi)
                                        .padding([.horizontal, .bottom])
                                }
                            }
                        }
                    }
                }
                
                if selectedResultTag == "Shiurim" || selectedResultTag == "All" {
                    if let sortables = model.sortables {
                        ForEach(sortables, id: \.self) { sortable in
                            if let video = sortable.video {
                                VideoCardView(video: video)
                                    .contextMenu {
                                        Button("Play") {}
                                    }
                                    .padding([.horizontal, .bottom])
                            } else if let audio = sortable.audio {
                                AudioCardView(audio: audio)
                                    .contextMenu {
                                        Button("Play") {}
                                    }
                                    .padding([.horizontal, .bottom])
                            }
                        }
                    }
                }
            }
            .alert(isPresented: $showAlert, content: {
                Alert(title: Text(alertTitle), message: Text(alertBody), dismissButton: Alert.Button.default(Text("OK")))
        })
            .navigationBarHidden(true)
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
            //            .background(Color.gray.ignoresSafeArea())
            .sheet(isPresented: $presentingSearchView) {
                SearchView()
                //                    .background(Color.yellow)
            }
        }
    }
    static var previews: some View {
        binding()
    }
}
