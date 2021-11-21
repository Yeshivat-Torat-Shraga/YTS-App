//
//  LogoView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/16/21.
//

import SwiftUI

struct LogoView: View {
    enum logoSize {
        case tiny
        case small
        case medium
        case large
        case huge
    }
    var size: logoSize
    var frameSize: (width: CGFloat, height: CGFloat) {
        switch size {
        case .tiny:
            return (32, 32)
        case .small:
            return (54, 54)
        case .medium:
            return (100, 100)
        case .large:
            return (300, 300)
        case .huge:
            return (500, 500)
        }
    }
    var body: some View {
        Image("Logo")
            .resizable()
            .frame(width: frameSize.width, height: frameSize.height)
    }
}

struct LogoView_Previews: PreviewProvider {
    static var previews: some View {
        LogoView(size: .medium)
    }
}
