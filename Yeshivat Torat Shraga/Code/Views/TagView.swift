//
//  TagView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/12/2021.
//

import SwiftUI

struct TagView: View {
    @ObservedObject var model: TagModel
    @EnvironmentObject var audioPlayerModel: AudioPlayerModel
    
    init(tag: Tag) {
        self.model = TagModel(tag: tag)
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(model.tag.name)
                    .fontWeight(.bold)
                    .font(.largeTitle)
                
                Spacer()
                
                if let category = model.tag as? Category {
                    DownloadableImage(object: category)
                        .frame(width: 100, height: 70)
                        .aspectRatio(contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: UI.cornerRadius))
                        .clipped()
                        .shadow(radius: UI.shadowRadius)
                }
            }
            .padding([.horizontal, .top])
            
            Divider()
            
            
            ScrollView {
                VStack {
                    if let sortables = model.sortables {
                        if sortables.count > 0 {
                            if model.tag.isParent {
                                ForEach(sortables.keys.sorted(by: {$0.name < $1.name}), id: \.self) { subCategory in
                                    HStack {
                                        Text(subCategory.name)
                                            .font(.title3)
                                            .bold()
                                        Spacer()
                                    }
                                    .padding(.top)
                                    if let contentGroup = sortables[subCategory] {
                                        ForEach(contentGroup, id: \.self) { sortable in
                                            if let video = sortable.video {
                                                VideoCardView(video: video, showAuthor: true)
                                            } else if let audio = sortable.audio {
                                                AudioCardView(audio: audio, showAuthor: true)
                                            }
                                            
                                        }
                                    }
                                }
                            } else {
                                if let category = sortables[model.tag] {
                                    ForEach(category, id: \.self) { sortable in
                                        if let video = sortable.video {
                                            VideoCardView(video: video, showAuthor: true)
                                        } else if let audio = sortable.audio {
                                            AudioCardView(audio: audio, showAuthor: true)
                                        }
                                        
                                    }
                                }
                            }
                        } else {
                            VStack {
                                Text("Sorry, no shiurim here yet.")
                                    .bold()
                                    .font(.title2)
                                    .padding(.vertical)
                                Text("Check again in a little bit.")
                            }
                            .multilineTextAlignment(.center)
                            .padding()
                        }
                    } else {
                        ProgressView()
                            .progressViewStyle(YTSProgressViewStyle())
                    }
                }
                .padding([.horizontal, .top])
            }
        }
        .background(
            Blur(style: .systemThinMaterial).edgesIgnoringSafeArea(.vertical)
        )
        .onAppear {
            self.model.loadOnlyIfNeeded()
        }
        .alert(isPresented: $model.showError, content: {
            Alert(
                title: Text("Error"),
                message: Text(
                    model.errorToShow?.getUIDescription() ??
                    "An unknown error has occured."),
                dismissButton: Alert.Button.default(
                    Text("Retry"),
                    action: {
                        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                            self.model.retry?()
                        }
                    }))
        })
    }
}

struct iOS14BorderedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color(hex: 0x526B98))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct TagView_Previews: PreviewProvider {
    static var previews: some View {
        TagView(tag: .sample)
            .background(LinearGradient(gradient: Gradient(stops: [Gradient.Stop(color: Color(hue: 0.1625910379800452, saturation: 0.8462154434387943, brightness: 0.8311787341014449, opacity: 1.0), location: 0.5724087641789364), Gradient.Stop(color: Color(hue: 0.6322852444935995, saturation: 0.8108159720179547, brightness: 0.7733789007347751, opacity: 1.0), location: 0.572469740647536)]), startPoint: UnitPoint.leading, endPoint: UnitPoint.top))
    }
}
