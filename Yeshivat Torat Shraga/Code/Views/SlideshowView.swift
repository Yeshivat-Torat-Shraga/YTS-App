//
//  ImageCarouselView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 13/01/2022.
//

import SwiftUI
import Combine

struct SlideshowView: View {
    private let slideDuration = 8.0 // Seconds
    private var slideshowImages: [SlideshowImage]
    private let swipeThreshhold: CGFloat = 50
    @AppStorage("slideshowAutoScroll") private var enableTimer = true
    @State private var timerSeconds = 0.0
    @State private var imageTabIndex = 0
    @State private var timer: Publishers.Autoconnect<Timer.TimerPublisher>
    
    init(_ slideshowImages: [SlideshowImage]) {
        self.slideshowImages = slideshowImages
        timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    }
    
    var body: some View {
        if slideshowImages.count < 1 {
            EmptyView()
        } else {
        SingleAxisGeometryReader(axis: .horizontal) { width in
            TabView(selection: $imageTabIndex) {
                ForEach(slideshowImages.indices, id: \.self) { index in
                    let image = slideshowImages[index].downloadableImage
                    image
                        .scaledToFill()
                        .frame(width: width)
                        .frame(minHeight: 250)
                        .overlay(
                            VStack(alignment: .leading) {
                                if let title = slideshowImages[index].name {
                                    Spacer()
                                    HStack {
                                        Text(title)
                                            .foregroundColor(.white)
                                            .padding(5)
                                            .font(.system(size: 12, weight: .medium ))
                                            .background(
                                                VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
                                                    .cornerRadius(UI.cornerRadius, corners: [.topRight])
                                            )
                                        Spacer()
                                    }
                                }
                            }
                        )
                        .clipped()
                        .tag(index)
                    
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .onReceive(timer) { _ in
                if enableTimer {
                    timerSeconds += 1
                    if timerSeconds >= slideDuration {
                        timerSeconds = 0
                        withAnimation {
                            imageTabIndex = (imageTabIndex + 1) % slideshowImages.count
                        }
                    }
                }
            }
        }
        .onChange(of: imageTabIndex) { _ in
            // Reset the timer that auto-changes the slides,
            // because we just manually changed the slide.
            timerSeconds = 0
        }
        .onDisappear {
            self.timer.upstream.connect().cancel()
        }
        .onAppear {
            timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
        }
    }
    }
}

struct ImageCarouselView_Previews: PreviewProvider {
    static let images: [SlideshowImage] = [
        SlideshowImage(image:Image("SampleRabbi"), name: "Rabbi Silber"),
//        SlideshowImage(image:Image("Logo"), name: "Shraga Logo"),
        SlideshowImage(image:Image("parsha")),
        SlideshowImage(image:Image("chanuka")),
    ]
    
    static var previews: some View {
        HomeView()
            .foregroundColor(Color("ShragaBlue"))
            .accentColor(Color("ShragaBlue"))
            .environmentObject(AudioPlayerModel(player: Player()))
            .environmentObject(Favorites())
    }
}
