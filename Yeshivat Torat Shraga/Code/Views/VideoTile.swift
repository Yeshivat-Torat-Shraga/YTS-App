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
        Button(action: {
        }) {
            ZStack {
                DownloadableImage(object: video)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 250, height: 150)
                Blur(style: .systemUltraThinMaterial)
                VStack {
                    HStack {
                        VStack {
                            HStack {
                                Text(video.title)
                                    .font(.title2)
                                    .bold()
                                Spacer()
                            }
                            
                            HStack {
                                Text(video.author.name)
                                Spacer()
                            }
                        }
                        if let detailedRabbi = video.author as? DetailedRabbi {
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
                            Text(video.date.formatted(date: .long, time: .omitted))
                        } else {
                            if let month = Date.monthNameFor(video.date.get(.month)) {
                                let yearAsString = String(video.date.get(.year))
                                Text("\(month) \(video.date.get(.day)), \(yearAsString)")
                            }
                        }
                        Spacer()
                        if let duration = video.duration {
                            Text(timeFormattedMini(totalSeconds: duration))
                        }
                    }.font(.caption)
                }
                .padding()
                .foregroundColor(.primary)
            }
            .frame(width: 250, height: 150)
            .clipped()
            
            
        }
                .buttonStyle(BackZStackButtonStyle())
        .cornerRadius(UI.cornerRadius)
        .shadow(radius: UI.shadowRadius)
    }
}

struct VideoTile_Previews: PreviewProvider {
    static var previews: some View {
        VideoTile(video: .sample)
            .foregroundColor(Color("ShragaBlue"))
    }
}
