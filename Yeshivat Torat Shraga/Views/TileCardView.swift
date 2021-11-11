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
// Shiurim (A/V), Rebbeimm, Categories/Topics
// and maybe the slideshow. Not sure about that yet.

struct TileCardView<Content: Tileable>: View {
    enum TileSize {
        case small
        case wide
        case large
    }
    
    var content: Tileable
    var size: TileSize
    
    private var frameSize: (width: CGFloat, height: CGFloat) {
        switch size {
        case .small:
            return (100, 100)
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
        case .wide:
            return 10
        case .large:
            return 12
        }
    }
    
    var body: some View {
        content.image?
            .resizable()
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
                                    .cornerRadius(15, corners: [.topRight, .bottomLeft])
                            )
                        Spacer()
                    }
                }
            )
            .cornerRadius(15)

    }
}

protocol Tileable: URLImageable {
    var name: String { get }
}

struct TileCardView_Previews: PreviewProvider {
    static var previews: some View {
        TileCardView<Rabbi>(content: Rabbi.samples[0], size: .small)
    }
}
