//
//  TagView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/12/2021.
//

import SwiftUI

struct TagView: View {
    @ObservedObject var model: TagModel
    var tag: Tag
    
    init(tag: Tag) {
        self.tag = tag
        self.model = TagModel(tag: tag)
    }
    
    var body: some View {
            VStack {
                HStack() {
                    Text(tag.name)
                        .fontWeight(.bold)
                        .font(.largeTitle)
                        .padding()
                    Spacer()
                }
                Spacer()
                ScrollView {
                    VStack {
                        HStack {
                            Text("Recently Uploaded")
                                .font(.title3)
                                .bold()
                            Spacer()
                        }
                        if let sortables = model.sortables {
                            ForEach(sortables, id: \.self) { sortable in
                                if let video = sortable.video {
                                    VideoCardView(video: video)
                                        .contextMenu {
                                            Button("Play") {}
                                        }
                                } else if let audio = sortable.audio {
                                    AudioCardView(audio: audio)
                                        .contextMenu {
                                            Button("Play") {}
                                        }
                                }
                            }
                        }
                    }
                    .padding([.horizontal, .top])
                }
                Spacer()
            }
            .background(
                Blur(style: .systemThinMaterial).edgesIgnoringSafeArea(.vertical)
            )
            .onAppear {
                self.model.load()
            }
    }
}

struct TagView_Previews: PreviewProvider {
    static var previews: some View {
        TagView(tag: .sample)
            .background(LinearGradient(gradient: Gradient(stops: [Gradient.Stop(color: Color(hue: 0.1625910379800452, saturation: 0.8462154434387943, brightness: 0.8311787341014449, opacity: 1.0), location: 0.5724087641789364), Gradient.Stop(color: Color(hue: 0.6322852444935995, saturation: 0.8108159720179547, brightness: 0.7733789007347751, opacity: 1.0), location: 0.572469740647536)]), startPoint: UnitPoint.leading, endPoint: UnitPoint.top))
    }
}
