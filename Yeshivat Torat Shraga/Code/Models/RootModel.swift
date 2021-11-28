//
//  Root.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 11/9/21.
//

import Foundation
import SwiftUI

class RootModel: ObservableObject {
    static var audioPlayer: AudioPlayer = AudioPlayer()
    static var audioPlayerBinding: Binding<AudioPlayer> = Binding {
        audioPlayer
    } set: { val in
        audioPlayer = val
    }
    
    init() {
        let appearance = UITabBar.appearance()
        appearance.standardAppearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)
        if #available(iOS 15.0, *) {
                let scrollEdgeAppearance = UITabBarAppearance()
                scrollEdgeAppearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)
                appearance.scrollEdgeAppearance = scrollEdgeAppearance
        }
    }
}
