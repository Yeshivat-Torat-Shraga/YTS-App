//
//  AudioTile.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 12/8/21.
//

import SwiftUI

struct AudioTile: View {
    var audio: Audio
    
    var body: some View {
        VStack {
            HStack {
                Text(audio.title)
                    .font(.title)
                    .bold()
                if let author = audio.author as? DetailedRabbi {
                DownloadableImage(object: author)
                        .aspectRatio(contentMode: .fit)
                        .clipShape(Circle())
                        .frame(width: 70, height: 70)
                }
            }
            HStack {
                if #available(iOS 15.0, *) {
                    Text(audio.date.formatted(date: .long, time: .omitted))
                } else {
                    
                    if let month = Date.monthNameFor(audio.date.get(.month)) {
                            HStack {
                                let yearAsString = String(audio.date.get(.year))
                                Image(systemName: "calendar")
                                Text("\(month) \(audio.date.get(.day)), \(yearAsString)")
                                    .foregroundColor(Color("Gray"))
                            }
                        }
                }
                
                Spacer()
                
                if let duration = audio.duration {
                Text(timeFormattedMini(totalSeconds: duration))
                }
            }
        }.background(LinearGradient(colors: [Color("ShragaBlue"), Color("ShragaBlue").lighter()], startPoint: .bottomLeading, endPoint: .topTrailing))
    }
}

struct AudioTile_Previews: PreviewProvider {
    static var previews: some View {
        AudioTile(audio: .sample)
            .previewLayout(.fixed(width: 350, height: 170))
    }
}
