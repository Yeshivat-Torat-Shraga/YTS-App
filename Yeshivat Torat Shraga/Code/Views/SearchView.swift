//
//  SearchView.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 12/20/21.
//

import SwiftUI

struct SearchView: View {
    @ObservedObject var model = SearchModel()
    @State var searchText = ""
    @State var showAlert = false
    var body: some View {
        VStack {
            ZStack {
                Rectangle()
                    .foregroundColor(Color("ShragaBlue"))
                    .opacity(0.1)
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("", text: $searchText, onCommit: {
                        showAlert = true
                    })
                    .placeholder(when: searchText.isEmpty) {
                        Text("Search...").foregroundColor(Color("ShragaGold"))
                    }
                    
//                                .foregroundColor(Color("ShragaGold"))
                }
                .foregroundColor(Color("ShragaGold"))
                .padding(.leading, 13)
                
            }
            .frame(height: 40)
            .cornerRadius(13)
            .padding()
            Spacer()
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
