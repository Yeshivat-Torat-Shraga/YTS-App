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
    private let enableAutoScroll = false // Maybe make this a toggle in settings?
    @State private var timerSeconds = 0.0
    @State private var imageTabIndex = 0
    @State private var timer: Publishers.Autoconnect<Timer.TimerPublisher>
    
    init(_ slideshowImages: [SlideshowImage]) {
        self.slideshowImages = slideshowImages
        timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    }
    
    var body: some View {
        SingleAxisGeometryReader(axis: .horizontal) { width in
            TabView(selection: $imageTabIndex) {
                ForEach(slideshowImages.indices) { index in
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
                        .contextMenu {
                            if let image = slideshowImages[index].image {
                                Button(action: {
                                    let activityController = UIActivityViewController(activityItems: [image], applicationActivities: [])
                                    
                                    UIApplication.shared.windows.first?.rootViewController!.present(activityController, animated: true, completion: nil)
                                    
                                }) {
                                    HStack {
                                        Text("Share")
                                        Spacer()
                                        Image(systemName: "square.and.arrow.up")
                                    }
                                }
                            }
                        }
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
