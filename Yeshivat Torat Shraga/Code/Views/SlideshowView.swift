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
    private var slideshowImages: [DownloadableImage<SlideshowImage>]
    private let swipeThreshhold: CGFloat = 50
    @State private var imageTabIndex = 0
    @State private var timer: Publishers.Autoconnect<Timer.TimerPublisher>
    
    init(_ slideshowImages: [DownloadableImage<SlideshowImage>]) {
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
            
//        SingleAxisGeometryReader(axis: .vertical) { height in
            TabView(selection: $imageTabIndex) {
                ForEach(slideshowImages.indices) { index in
                    let image = slideshowImages[index]
                    image
//                        .resizable()
                        .scaledToFill()
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
//            .frame(height: 250)
//            .cornerRadius(14)
            .onReceive(self.timer) { _ in
                withAnimation {
                    imageTabIndex = (imageTabIndex + 1) % slideshowImages.count
                }
            }
//        }
        //        .clipped()
    }
}

struct ImageCarouselView_Previews: PreviewProvider {
    static let images: [DownloadableImage<SlideshowImage>] = [
        DownloadableImage(object: SlideshowImage(image:Image("SampleRabbi"))),
        DownloadableImage(object: SlideshowImage(image:Image("Logo"))),
        DownloadableImage(object: SlideshowImage(image:Image("parsha"))),
        DownloadableImage(object: SlideshowImage(image:Image("chanuka"))),
    ]
    
    static var previews: some View {
        SlideshowView(images)
//            .cornerRadius(14)
    }
}
