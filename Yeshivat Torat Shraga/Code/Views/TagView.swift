//
//  TagView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/12/2021.
//

import SwiftUI

struct TagView: View {
    @ObservedObject var model: TagViewModel
    var tag: Tag
    
    init(tag: Tag) {
        self.tag = tag
        self.model = TagViewModel(tag: tag)
    }
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct TagView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TagView(tag: .sample)
                .navigationTitle(Tag.sample.name)
        }
    }
}
