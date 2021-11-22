//
//  TileCardView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/11/21.
//

import SwiftUI

// This view needs to be set up that
// it can take in any content that conforms
// to the TileContent protocol. This would be
// Shiurim (A/V), Rebbeim, Categories/Topics
// and maybe the slideshow. Not sure about that yet.

struct TileCardView<Content: Tileable>: View {
    enum TileSize {
        case small
        case medium
        case wide
        case large
    }
    
    var content: Content
    var size: TileSize
    
    private var frameSize: (width: CGFloat, height: CGFloat) {
        switch size {
        case .small:
            return (100, 100)
        case .medium:
            return (150, 150)
        case .wide:
            return (200, 100)
        case .large:
            return (200, 200)
        }
    }
    
    private var fontSize: CGFloat {
        switch size {
        case .small:
            return 8
        case .wide, .medium:
            return 12
        case .large:
            return 14
        }
    }
    
    init(content: Content, size: TileSize) {
        self.size = size
        self.content = content
        if (self.content.image == nil && self.content.imageURL == nil) {
            self.content.image = Image("AudioPlaceholder")
        }
    }
    
    var body: some View {
        DownloadableImage(object: content)
            .background(Color("ShragaGold"))
            .aspectRatio(contentMode: .fill)
            .frame(width: frameSize.width, height: frameSize.height)
            .clipped()
            .overlay(
                VStack {
                    Spacer()
                    HStack {
                        Text(content.name)
                            .foregroundColor(.white)
                            .padding(5)
                            .font(.system(size: fontSize, weight: .medium ))
                            .background(
                                VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
                                    .cornerRadius(8, corners: [.topRight, .bottomLeft])
                            )
                        Spacer()
                    }
                }
            )
            .cornerRadius(8)
    }
}

struct TileCardView_Previews: PreviewProvider {
    static var previews: some View {
        TileCardView<DetailedRabbi>(content: DetailedRabbi.samples[0], size: .medium)
    }
}
