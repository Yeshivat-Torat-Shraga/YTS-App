//
//  NewsView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 10/12/2021.
//

import SwiftUI

struct NewsView: View {
    var body: some View {
        NavigationView {
            Text("News View")
                .navigationTitle("YTS News")
        }
    }
}

struct NewsView_Previews: PreviewProvider {
    static var previews: some View {
        NewsView()
    }
}
