//
//  ParentTagView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 5/17/22.
//

import SwiftUI

struct ParentTagView: View {
    @ObservedObject private var model: ParentTagModel
    @ObservedObject private var tag: Tag
    init(_ tag: Tag) {
        self.tag = tag
        self.model = ParentTagModel(tag)
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

            
            ScrollView {
                LazyVStack {
                    if model.runningInitialLoad {
                        ProgressView()
                            .progressViewStyle(YTSProgressViewStyle())
                    } else {
                    ForEach(model.content.keys.sorted(by: {$0.name < $1.name}), id: \.id) { child in
                        if let sortables = model.content[child]!.sortables {
                            LabeledDivider(title: child.name)
                            ForEach(sortables, id: \.self) { sortable in
                                if let audio = sortable.audio {
                                    AudioCardView(audio: audio, showAuthor: true)
                                } else if let video = sortable.video {
                                    VideoCardView(video: video, showAuthor: true)
                                }
                            }
                            LoadMoreView(
                                loadingContent: Binding(get: {
                                    model.content[child]!.metadata.isLoadingContent
                                }, set: {
                                    model.content[child]!.metadata.isLoadingContent = $0
                                }),
                                showingError: .constant(false),
                                retreivedAllContent: Binding(get: {
                                    model.content[child]!.metadata.finalCall
                                }, set: {
                                    model.content[child]!.metadata.finalCall = $0
                                }),
                                loadMore: {
                                    model.loadIndividualChild(child: child, next: 7)
                                })
                            //                            if !content[tag]!.metadata.finalCall {
                        }
                        // Make a loadMore view.
                        // The catch is, we need a function that will
                        // load more content specifically to *this* tag.
                        // This should be easy enough in the model
                        //                            }
                    }
                }
                }
                .padding([.horizontal, .top])
            }
            
        }
        .background(
            Blur(style: .systemThinMaterial).edgesIgnoringSafeArea(.vertical)
        )
        .onAppear {
            model.loadOnlyIfNeeded()
        }
        
    }
}

struct ParentTagView_Previews: PreviewProvider {
    static var previews: some View {
        ParentTagView(.sample)
    }
}
