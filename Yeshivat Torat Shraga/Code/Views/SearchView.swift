//
//  SearchView.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 12/20/21.
//

import SwiftUI

struct SearchView: View {
    @State var searchText = ""
    
    var body: some View {
        VStack {
            ZStack {
                Rectangle()
                    .foregroundColor(Color("ShragaBlue"))
                    .opacity(0.1)
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("", text: $searchText)
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
            .padding(.horizontal)
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
