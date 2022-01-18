//
//  ImageCarouselView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 13/01/2022.
//

import SwiftUI
import Combine

struct SlideshowView: View {
    private var timerDelay: Double = 7
    private var slideshowImages: [SlideshowImage]
    private let swipeThreshhold: CGFloat = 50
    @State private var imageTabIndex = 0
    @State private var timer: Publishers.Autoconnect<Timer.TimerPublisher>
    
    init(_ slideshowImages: [SlideshowImage]) {
        self.slideshowImages = slideshowImages
        self.timer = Timer.publish(every: timerDelay, on: .main, in: .common).autoconnect()
    }
    
    func handleSwipe(translation: CGFloat) {
        timer.upstream.connect().cancel()
        timer = Timer.publish(every: timerDelay, on: .main, in: .common).autoconnect()
        withAnimation {
            if translation < -swipeThreshhold {
                imageTabIndex = (imageTabIndex + 1) % slideshowImages.count
            } else if translation > swipeThreshhold {
                imageTabIndex = (imageTabIndex - 1) % slideshowImages.count
                if imageTabIndex < 0 {
                    imageTabIndex = slideshowImages.count - 1
                }
            }
        }
    }
    
    var body: some View {
        SingleAxisGeometryReader(axis: .horizontal) { width in
            TabView(selection: $imageTabIndex) {
                ForEach(slideshowImages.indices) { index in
                    let image = slideshowImages[index].downloadableImage
                    image
                        .scaledToFill()
                        .frame(width: width, height: 250)
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
                        .highPriorityGesture(
                            DragGesture()
                                .onEnded {
                                    handleSwipe(translation: $0.translation.width)
                                }
                        )
                    
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .onReceive(self.timer) { _ in
                withAnimation {
                    imageTabIndex = (imageTabIndex + 1) % slideshowImages.count
                }
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
    }
}
