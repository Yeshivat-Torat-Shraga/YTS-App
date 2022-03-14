//
//  RabbiCardView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 04/01/2022.
//

import SwiftUI

struct RabbiCardView: View {
    var rabbi: Rabbi
    
    var body: some View {
        VStack {
            HStack {
                Text(rabbi.name)
                    .fontWeight(.bold)
                    .font(.title2)
//                    .bold()
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(Color("ShragaBlue"))
                    .padding(.trailing)
                Spacer()
                if let detailedRabbi = rabbi as? DetailedRabbi {
                    DownloadableImage(object: detailedRabbi)
                        .aspectRatio(contentMode: .fill)
                        .clipShape(Circle())
                        .frame(width: 65, height: 65)
                        .clipped()
                }
            }
            
//            HStack {
//                Text(rabbi.name)
//                Spacer()
//            }
            
//            Spacer()
            
//            HStack {
//                if #available(iOS 15.0, *) {
//                    HStack {
//                        Text(audio.date.formatted(date: .long, time: .omitted))
//                            .foregroundColor(Color("Gray"))
//                    }
//                } else {
//
//                    if let month = Date.monthNameFor(audio.date.get(.month)) {
//                        HStack {
//                            let yearAsString = String(audio.date.get(.year))
//                            Text("\(month) \(audio.date.get(.day)), \(yearAsString)")
//                                .foregroundColor(Color("Gray"))
//                        }
//                    }
//                }
//
//                Spacer()
//
//                if let duration = audio.duration {
//                    Text(timeFormattedMini(totalSeconds: duration))
//                }
//            }.foregroundColor(Color("Gray"))
//                .font(.caption)
        }
        .padding()
        .background(
            Rectangle()
                .fill(Color.white)
        )
//        .buttonStyle(BackZStackButtonStyle())
        .cornerRadius(UI.cornerRadius)
        .shadow(radius: UI.shadowRadius)
//        .frame(height: 150)
//        .frame(maxWidth: 350)
//        .padding()
    }
}


struct RabbiCardView_Previews: PreviewProvider {
    static var previews: some View {
        RabbiCardView(rabbi: DetailedRabbi.samples[0])
            .foregroundColor(Color("ShragaBlue"))
            .accentColor(Color("ShragaBlue"))
    }
}
