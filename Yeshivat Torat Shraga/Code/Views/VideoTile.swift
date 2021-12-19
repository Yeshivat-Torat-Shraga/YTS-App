//
//  VideoTile.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 12/15/21.
//

import SwiftUI

struct VideoTile: View {
    var video: Video
    
    var body: some View {
        ZStack {
            DownloadableImage(object: video)
                .overlay(Color.black.opacity(0.2))
                .aspectRatio(contentMode: .fill)
//            LinearGradient(colors: [.white.opacity(0.5), .clear], startPoint: .bottomLeading, endPoint: .bottom)
            LinearGradient(colors: [.white.opacity(0.5), .clear], startPoint: .leading, endPoint: .trailing)
        }
        .frame(width: 250, height: 150)
        .clipped()
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}

struct VideoTile_Previews: PreviewProvider {
    static var previews: some View {
        VideoTile(video: .sample)
    }
}
