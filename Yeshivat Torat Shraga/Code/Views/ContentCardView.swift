//
//  ContentCardView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 02/02/2022.
//

import SwiftUI

struct ContentCardView<Content: YTSContent>: View {
    
    let content: Content
    
    init(content: Content) {
        self.content = content
    }
    
    var body: some View {
        Button(action: {
        }) {
            ZStack {
                if content.sortable.audio != nil {
                    // If the card is for Audios
                    LinearGradient(
                        gradient: Gradient(
                            stops: [
                                Gradient.Stop(
                                    color: Color(
                                        hue: 0.616,
                                        saturation: 0.431,
                                        brightness: 0.510),
                                    location: 0),
                                Gradient.Stop(
                                    color: Color(
                                        hue: 0.610,
                                        saturation: 0.5,
                                        brightness: 0.19),
                                    location: 1),
                            ]
                        ),
                        startPoint: UnitPoint.bottomLeading,
                        endPoint: UnitPoint.trailing)
                } else {
                    // If the card is for Videos
                    DownloadableImage(object: content)
                }
                Blur(style: .systemUltraThinMaterial)
                VStack {
                    HStack {
                        VStack {
                            HStack {
                                Text(content.title)
                                    .font(.title2)
                                    .bold()
                                Spacer()
                            }
                            
                            HStack {
                                Text(content.author.name)
                                Spacer()
                            }
                        }
                        if let detailedRabbi = content.author as? DetailedRabbi {
                            DownloadableImage(object: detailedRabbi)
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .background(Color("Gray"))
                                .clipShape(Circle())
                                .clipped()
                                .shadow(radius: 2)
                        }
                    }
                    Spacer()
                    HStack {
                        if #available(iOS 15.0, *) {
                            Text(content.date.formatted(date: .long, time: .omitted))
                        } else {
                            if let month = Date.monthNameFor(content.date.get(.month)) {
                                let yearAsString = String(content.date.get(.year))
                                Text("\(month) \(content.date.get(.day)), \(yearAsString)")
                            }
                        }
                        Spacer()
                        if let duration = content.duration {
                            HStack {
                                Image(systemName: content.sortable.audio != nil
                                      ? "speaker.wave.2"
                                      : "play")
                                    .scaleEffect(1.35)
                                Text(timeFormattedMini(totalSeconds: duration))
                            }
                        }
                    }.font(.caption)
                }
                .padding()
                .clipped()
            }
            .foregroundColor(.primary)
            .frame(width: 250, height: 130)
            .clipped()
            
            
        }
        .buttonStyle(BackZStackButtonStyle())
        .cornerRadius(UI.cornerRadius)
        .shadow(radius: UI.shadowRadius)
    }
}

struct ContentCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ContentCardView(content: Audio.sample)
            ContentCardView(content: Video.sample)
        }
        .padding()
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.dark)
    }
}
