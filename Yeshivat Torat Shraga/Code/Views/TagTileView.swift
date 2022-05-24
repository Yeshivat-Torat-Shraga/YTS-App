//
//  TagView.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 12/2/21.
//

import SwiftUI
import FirebaseAnalytics

struct TagTileView: View {
    @State var isShowingSheet = false
    @EnvironmentObject var audioPlayerModel: AudioPlayerModel
    @EnvironmentObject var favoritesManager: Favorites
    @EnvironmentObject var player: Player
    @State private var colorMix: [Color] = [[.blue, .green], [.blue, .yellow], [.yellow, .green], [.red, .orange], [.orange, .yellow], [.yellow, .red], [.pink, .white], [.purple, .blue], [.white, .blue], [.white, .blue, .green], [.red, .orange, .yellow]].randomElement()!
    var tag: Tag
    @State var tagView: AnyView
    
    init(_ tag: Tag) {
        self.tag = tag
        if tag.isParent {
            self.tagView = AnyView(ParentTagView(tag))
        } else {
            self.tagView = AnyView(TagView(tag))
        }
    }
    
    var body: some View {
        Button(action: {
            isShowingSheet = true
            Analytics.logEvent("opened_category", parameters: [
                "category_name": tag.name,
            ])

        }) {
            if let category = tag as? Category {
                ZStack {
                    category.icon
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .overlay(Rectangle().opacity(0.2))
                    Text(category.name)
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.5)
                        .padding()
                        .padding()
                }
                .frame(height: 110)
                .frame(minWidth: 150)
                .aspectRatio(contentMode: .fill)
                .clipped()
                .cornerRadius(UI.cornerRadius)
                .shadow(radius: UI.shadowRadius)
            } else {
                Group {
                    Text(tag.name)
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                        .padding()
                        .padding()
                }
                .frame(height: 110)
                .frame(minWidth: 150)
                .background(LinearGradient(
                    colors: colorMix,
                    startPoint: .bottomLeading,
                    endPoint: .topTrailing)
                                .cornerRadius(UI.cornerRadius)
                                .overlay(Rectangle()
                                            .opacity(0.2)))
                .shadow(radius: UI.shadowRadius)
            }
        }
        .sheet(isPresented: $isShowingSheet) {
            tagView
                .background(BackgroundClearView())
                .environmentObject(audioPlayerModel)
                .environmentObject(favoritesManager)
                .environmentObject(player)
        }
    }
}

struct TagTileView_Previews: PreviewProvider {
    static var player = Player()
    static var previews: some View {
        TagTileView(.sample)
            .previewLayout(.sizeThatFits)
            .environmentObject(Favorites())
            .environmentObject(AudioPlayerModel(player: TagTileView_Previews.player))
            .environmentObject(TagTileView_Previews.player)
    }
}
