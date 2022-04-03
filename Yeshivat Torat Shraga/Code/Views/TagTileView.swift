//
//  TagView.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 12/2/21.
//

import SwiftUI

struct TagTileView: View {
    @State var isShowingSheet = false
    var tag: Tag
    
    init(_ tag: Tag) {
        self.tag = tag
    }
    
    var body: some View {
        Button(action: {isShowingSheet = true}) {
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
                    colors: randomColorMix(),
                    startPoint: .bottomLeading,
                    endPoint: .topTrailing)
                                .cornerRadius(UI.cornerRadius)
                                .overlay(Rectangle()
                                            .opacity(0.2)))
                .shadow(radius: UI.shadowRadius)
            }
        }
        .sheet(isPresented: $isShowingSheet) {
            TagView(tag: tag)
                .background(BackgroundClearView())
        }
    }
    
    func randomColorMix() -> [Color] {
        let mixes: [[Color]] = [[.blue, .green], [.blue, .yellow], [.yellow, .green], [.red, .orange], [.orange, .yellow], [.yellow, .red], [.pink, .white], [.purple, .blue], [.white, .blue], [.white, .blue, .green], [.red, .orange, .yellow]]
        
        return mixes.randomElement()!
    }
}

struct TagTileView_Previews: PreviewProvider {
    static var previews: some View {
        TagTileView(Tag("Parsha"))
            .previewLayout(.sizeThatFits)
    }
}
