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
    
    init(_ tag: Tag) {
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
                LazyVStack {
                    if let sortables = model.sortables {
                        if sortables.count > 0 {
                            HStack {
                                Text("Recently Uploaded")
                                    .font(.title2)
                                    .bold()
                                Spacer()
                            }
                                    ForEach(sortables, id: \.self) { sortable in
                                        if let video = sortable.video {
                                            VideoCardView(video: video, showAuthor: true)
                                        } else if let audio = sortable.audio {
                                            AudioCardView(audio: audio, showAuthor: true)
                                        }
                                        
                                    }
                            Spacer()
                            
                            LoadMoreView(
                                loadingContent: Binding(get: {
                                    model.loadingContent
                                }, set: {
                                    model.loadingContent = $0
                                }),
                                showingError: Binding(get: {
                                    model.showError
                                }, set: {
                                    model.showError = $0
                                }),
                                retreivedAllContent: Binding(get: {
                                    model.retreivedAllContent
                                }, set: {
                                    model.retreivedAllContent = $0
                                }),
                                loadMore: {
                                    model.load()
                                })
//                            }
                        } else {
                            VStack {
                                Text("Sorry, no shiurim here yet.")
                                    .bold()
                                    .font(.title2)
                                
                                Spacer().frame(height: 6)
                                
                                Text("Check again in a little bit.")
                            }
                            .multilineTextAlignment(.center)
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
            self.model.initialLoad()
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

struct TagView_Previews: PreviewProvider {
    static var previews: some View {
        TagView(.sample)
            .background(LinearGradient(gradient: Gradient(stops: [Gradient.Stop(color: Color(hue: 0.1625910379800452, saturation: 0.8462154434387943, brightness: 0.8311787341014449, opacity: 1.0), location: 0.5724087641789364), Gradient.Stop(color: Color(hue: 0.6322852444935995, saturation: 0.8108159720179547, brightness: 0.7733789007347751, opacity: 1.0), location: 0.572469740647536)]), startPoint: UnitPoint.leading, endPoint: UnitPoint.top))
    }
}
