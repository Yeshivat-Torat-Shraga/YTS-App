//
//  SearchView.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 12/20/21.
//

import SwiftUI

struct SearchView: View {
    @ObservedObject var model = SearchModel()
    @State var selectedResultType = "Rebbeim"
    @State var searchText = ""
    @State var showAlert = false
    var body: some View {
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
                        Text("Search...").foregroundColor(Color("ShragaGold"))
                    }
                    
                }
                .foregroundColor(Color("ShragaGold"))
                .padding(.leading, 13)
                
            }
            .frame(height: 40)
            .cornerRadius(13)
            .padding([.top, .horizontal])

            Picker("Result Type", selection: $selectedResultType) {
                Text("Rebbeim")
                    .tag("Rebbeim")
                Text("Shiurim")
                    .tag("Shiurim")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            if selectedResultType == "Shiurim" {
                if let sortables = model.sortables {
                    ForEach(sortables, id: \.self) { sortable in
                        if let video = sortable.video {
                            VideoCardView(video: video)
                                .contextMenu {
                                    Button("Play") {}
                                }
                                .padding([.horizontal, .top])
                        } else if let audio = sortable.audio {
                            AudioCardView(audio: audio)
                                .contextMenu {
                                    Button("Play") {}
                                }
                                .padding([.horizontal, .top])
                        }
                    }
                }
            } else if selectedResultType == "Rebbeim" {
                if let rebbeim = model.rebbeim {
                    ForEach(rebbeim, id: \.self) { rabbi in
//                        RabbiCardView(rabbi: rabbi)
                        Text(rabbi.name)
//                            .padding()
                    }
                }
            }
        }
        .alert(isPresented: $showAlert, content: {
            Alert(title: Text("Search Submitted"), message: Text(searchText), dismissButton: Alert.Button.default(Text("OK")))
        })
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
                .shadow(radius: 4)
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
