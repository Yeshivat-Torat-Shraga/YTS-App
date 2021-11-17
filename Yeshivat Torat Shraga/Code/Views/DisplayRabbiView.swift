//
//  DisplayRabbiView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/16/21.
//

import SwiftUI

struct DisplayRabbiView: View {
    @State var rabbi: DetailedRabbi
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct DisplayRabbiView_Previews: PreviewProvider {
    static var previews: some View {
        DisplayRabbiView(rabbi: DetailedRabbi.samples[0])
    }
}
