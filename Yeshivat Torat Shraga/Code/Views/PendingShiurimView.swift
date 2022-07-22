//
//  PendingShiurimView.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 7/22/22.
//

import SwiftUI

struct PendingShiurimView: View {
    @ObservedObject var model: PendingShiurimModel
    
    var miniPlayerShowing: Binding<Bool>
    
    init(miniPlayerShowing: Binding<Bool>) {
        self.model = PendingShiurimModel()
        self.miniPlayerShowing = miniPlayerShowing
    }
    
    var body: some View {
        ScrollView {
            LazyVStack {
                if let sortables = model.sortables {
                    ForEach(sortables, id: \.id) { content in
                        MiniContentBar(content: content)
                            .padding()
                        Divider()
                    }
                }
                
                LoadMoreView(loadingContent: $model.loadingContent, showingError: $model.showError, retreivedAllContent: $model.retreivedAllContent) {
                    model.load()
                }
                
                if miniPlayerShowing.wrappedValue {
                    Spacer().frame(height: UI.playerBarHeight)
                }
            }
        }
        .navigationTitle("Pending Shiurim")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    model.reload()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }
    
    struct MiniContentBar: View {
        var content: SortableYTSContent
        @EnvironmentObject var audioPlayerModel: AudioPlayerModel
        
        init(content: SortableYTSContent) {
            self.content = content
        }
        
        var body: some View {
            
            if let audio = content.audio {
                VStack {
                    HStack {
                        VStack {
                            HStack {
                                Text(audio.title)
                                    .font(.title3)
                                Spacer()
                            }
                            
                            Spacer()
                            
                            HStack {
                                Text(audio.author.name)
                                    .font(.subheadline)
                                Spacer()
                            }
                        }
                        Spacer()
                        EllipseButton(action: {
                            audioPlayerModel.play(audio: audio)
                        }, imageSystemName: "play.fill", foregroundColor: .primary, backgroundColor: .white)
                    }
                    
                    Spacer()
                    
                    HStack {
                        if let date = audio.date {
                            if let month = Date.monthNameFor(date.get(.month), short: true) {
                                HStack {
                                    let yearAsString = String(date.get(.year))
                                    Text("\(month) \(date.get(.day)), \(yearAsString)")
                                        .font(.footnote)
                                        .foregroundColor(Color("Gray"))
                                }
                            }
                        }
                        
                        Spacer()
                        
                        if let duration = audio.duration {
                            Text(timeFormatted(totalSeconds: duration))
                                .font(.footnote)
                                .foregroundColor(Color("Gray"))
                        }
                    }
                }
            }
        }
    }
}

struct PendingShiurimView_Previews: PreviewProvider {
    static var previews: some View {
        PendingShiurimView(miniPlayerShowing: .constant(false))
    }
}
