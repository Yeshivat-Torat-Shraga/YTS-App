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
        Button(action: {}) {
            VStack {
                HStack {
                    Text(audio.title)
                        .font(.title)
                        .bold()
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                        .padding(.trailing)
                    Spacer()
                    if let author = audio.author as? DetailedRabbi {
                    DownloadableImage(object: author)
                            .aspectRatio(contentMode: .fill)
                            .clipShape(Circle())
                            .frame(width: 65, height: 65)
                            .clipped()
                    }
                }
                
                HStack {
                    Text(audio.author.name)
                    Spacer()
                }
                
                Spacer()
                
                HStack {
                    if #available(iOS 15.0, *) {
                        HStack {
                            Text(audio.date.formatted(date: .long, time: .omitted))
                                .foregroundColor(Color("Gray"))
                        }
                    } else {
                        
                        if let month = Date.monthNameFor(audio.date.get(.month)) {
                                HStack {
                                    let yearAsString = String(audio.date.get(.year))
                                    Text("\(month) \(audio.date.get(.day)), \(yearAsString)")
                                        .foregroundColor(Color("Gray"))
                                }
                            }
                    }
                    
                    Spacer()
                    
                    if let duration = audio.duration {
                    Text(timeFormattedMini(totalSeconds: duration))
                    }
                }.foregroundColor(Color("Gray"))
                    .font(.caption)
            }
            .padding()
//            .background(Color.white)
            
//            .background(Rectangle()
//                            .fill(Color.white)
//                            .cornerRadius(UI.cornerRadius)
//                            .shadow(radius: UI.shadowRadius)
//            )
        }
        .background(Color(UIColor.systemBackground))
        .buttonStyle(BackZStackButtonStyle())
        .cornerRadius(UI.cornerRadius)
        .shadow(radius: UI.shadowRadius)
        .frame(height: 150)
        .frame(maxWidth: 350)
        .padding()
    }
}

struct AudioTile_Previews: PreviewProvider {
    static var previews: some View {
        AudioTile(audio: .sample)
            .previewLayout(.fixed(width: 450, height: 170))
    }
}
