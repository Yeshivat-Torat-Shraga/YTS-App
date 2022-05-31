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
        if let detailedRabbi = rabbi as? DetailedRabbi {
            NavigationLink(destination: DisplayRabbiView(rabbi: detailedRabbi)) {
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
                        DownloadableImage(object: detailedRabbi)
                            .aspectRatio(contentMode: .fill)
                            .clipShape(Circle())
                            .frame(width: 65, height: 65)
                            .clipped()
                    }
                }
            }
            .padding()
            .background(
                Rectangle()
                    .fill(Color.cardViewBG)
            )
            //        .buttonStyle(BackZStackButtonStyle())
            .cornerRadius(UI.cornerRadius)
            .shadow(radius: UI.shadowRadius)
            
        } else {
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
                }
            }
            .padding()
            .background(
                Rectangle()
                    .fill(Color.cardViewBG)
            )
            //        .buttonStyle(BackZStackButtonStyle())
            .cornerRadius(UI.cornerRadius)
            .shadow(radius: UI.shadowRadius)
        }
    }
}


struct RabbiCardView_Previews: PreviewProvider {
    static var previews: some View {
        RabbiCardView(rabbi: DetailedRabbi.sample)
            .foregroundColor(Color("ShragaBlue"))
            .accentColor(Color("ShragaBlue"))
            .preferredColorScheme(.light)
    }
}
