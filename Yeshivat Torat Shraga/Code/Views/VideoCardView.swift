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
        Button {
//            RootModel.videoPlayer.set(video: model.video)
            isShowingPlayerSheet = true
        } label: {
            HStack {
                DownloadableImage(object: model.video)
                    .overlay(Color.black.opacity(0.2))
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 125, height: 105)
                    .clipped()
                // Rest of card goes here:
                VStack {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(model.video.name)
                                .font(.title3)
                                .bold()
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                    }
                    
                    Spacer()
                    
                    HStack {
                        HStack {
                            if let date = model.video.date {
                                if let month = Date.monthNameFor(date.get(.month), short: true) {
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
                
                .padding()
            }
        }
        .buttonStyle(BackZStackButtonStyle())
        .frame(height: 105)
        .background(
            Rectangle()
                .fill(Color(UIColor.systemBackground))
                .cornerRadius(UI.cornerRadius)
        )
        .cornerRadius(UI.cornerRadius)
        .shadow(radius: UI.shadowRadius)
    }
}

struct VideoCardView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack {
                AudioCardView(audio: .sample)
                VideoCardView(video: .sample)
                AudioCardView(audio: .sample)
                VideoCardView(video: .sample)
            }
            .padding()
            .foregroundColor(Color("ShragaBlue"))
//            .background(Color.black)
        }
    }
}
