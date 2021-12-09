//
//  VideoCardView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 08/12/2021.
//

import SwiftUI

struct VideoCardView: View {
    @ObservedObject var model: VideoCardModel
    @State var isShowingPlayerSheet = false
    
    init(video: Video) {
        self.model = VideoCardModel(video: video)
    }
    
    var body: some View {
        HStack {
            DownloadableImage(object: model.video)
                .aspectRatio(contentMode: .fill)
                .frame(width: 75, height: 100)
            //                .clipped()
                .cornerRadius(10, corners: [.topLeft, .bottomLeft])
            
            // Rest of card goes here:
            VStack {
                HStack {
                    //                    Circle()
                    //                        .fill(LinearGradient(
                    //                            gradient: Gradient(
                    //                                stops: [
                    //                                    Gradient.Stop(
                    //                                        color: Color(
                    //                                            hue: 0.610,
                    //                                            saturation: 0.5,
                    //                                            brightness: 0.19),
                    //                                        location: 0),
                    //                                    Gradient.Stop(
                    //                                        color: Color(
                    //                                            hue: 0.616,
                    //                                            saturation: 0.431,
                    //                                            brightness: 0.510),
                    //                                        location: 1)]),
                    //                            startPoint: UnitPoint.bottomLeading,
                    //                            endPoint: UnitPoint.trailing))
                    //                        .frame(width: 35, height: 35)
                    //                        .overlay(
                    //                            Image(systemName: "play")
                    //                                .foregroundColor(Color("ShragaGold"))
                    //                        )
                    VStack(alignment: .leading) {
                        Text(model.video.name)
                            .font(.title3)
                            .bold()
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Button {
                        //                        RootModel.videoPlayer.set(video: model.video)
                        //                        isShowingPlayerSheet = true
                    } label: {
                        Image(systemName: "play.circle.fill")
                            .resizable()
                            .shadow(radius: 1)
                    }
                    .frame(width: 35, height: 35)
                    .padding()
                }
                HStack {
                    HStack {
                        if let date = model.video.date {
                            if let month = Date.monthNameFor(date.get(.month)) {
                                HStack {
                                    let yearAsString = String(date.get(.year))
                                    Image(systemName: "calendar")
                                    Text("\(month) \(date.get(.day)), \(yearAsString)")
                                        .foregroundColor(Color("Gray"))
                                }
                            }
                        }
                    }
                    Spacer()
                    HStack {
                        Text(timeFormattedMini(totalSeconds: model.video.duration ?? 0))
                            .foregroundColor(Color("Gray"))
                        Image(systemName: "clock")
                    }
                    .padding(.trailing, 5)
                }
                .font(.footnote)
            }
            
            .padding(.trailing)
        }
        .background(
            Rectangle()
                .fill(Color(UIColor.systemBackground))
                .opacity(01)
                .cornerRadius(10)
                .shadow(radius: 2)
        )
    }
}

struct VideoCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            AudioCardView(audio: .sample)
            VideoCardView(video: .sample)
        }
        .padding()
        .foregroundColor(Color("ShragaBlue"))
    }
}
