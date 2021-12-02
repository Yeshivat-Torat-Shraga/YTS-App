//
//  PlayBar.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 11/27/21.
//

import SwiftUI

struct PlayBar: View {
    @StateObject var model: PlayBarModel = PlayBarModel()
    var audioCurrentlyPlaying: Binding<Audio?>
    @State private var presenting = false
    
    init(audioCurrentlyPlaying: Binding<Audio?>) {
        self.audioCurrentlyPlaying = audioCurrentlyPlaying
    }
    
    var body: some View {
        if let audioCurrentlyPlaying = audioCurrentlyPlaying.wrappedValue {
            HStack {
                //                DownloadableImage(object: audioCurrentlyPlaying)
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .background(Color(UIColor.systemGray5))
                    .cornerRadius(3)
                    .padding(.vertical, 10)
                    .padding(.leading)
                    .padding(.trailing, 5)
                    .shadow(radius: 1)
                VStack {
                    HStack {
                        Text(audioCurrentlyPlaying.title)
                        Spacer()
                    }
                    HStack {
                        Text(audioCurrentlyPlaying.author.name)
                            .foregroundColor(Color("Gray"))
                        Spacer()
                    }
                }
                Spacer()
                HStack {
                    if RootModel.audioPlayer.player.timeControlStatus == .playing {
                        Button(action: {
//                            RootModel.audioPlayer.pause()
                            self.model.objectWillChange.send()
                        }, label: {
                            Image(systemName: "pause.fill")
                                .resizable()
                                .frame(width: 20, height: 25)
                        })
                    } else if RootModel.audioPlayer.player.timeControlStatus == .paused {
                        Button(action: {
//                            RootModel.audioPlayer.play()
                            self.model.objectWillChange.send()
                        }, label: {
                            Image(systemName: "play.fill")
                                .resizable()
                                .frame(width: 25, height: 25)
                        })
                    } else {
                        ProgressView().progressViewStyle(YTSProgressViewStyle())
                            .frame(width: 25, height: 25)
                    }
                    Button(action: {}, label: {
                        Image(systemName: "forward.fill")
                            .resizable()
                            .frame(width: 45, height: 25)
                    }).padding(.horizontal)
                }
                .foregroundColor(.black)
            }
            .frame(height: 80)
            .background(Button(action: {
                presenting = true
            }, label: {
                Blur()
            }).buttonStyle(BackZStackButtonStyle(percentage: 30)))
            .sheet(isPresented: $presenting) {
                RootModel.audioPlayer
            }
        } else {
            EmptyView()
        }
    }
}

struct PlayBar_Previews: PreviewProvider {
    static var previews: some View {
        PlayBar(audioCurrentlyPlaying: .constant(.sample))
            .previewLayout(.fixed(width: 350, height: 80))
    }
}
