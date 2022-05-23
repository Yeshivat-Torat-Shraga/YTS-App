//
//  AutoLoadMoreBarView.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 5/23/22.
//

import SwiftUI

struct AutoLoadMoreBar: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @Binding var loadingContent: Bool
    @Binding var showingError: Bool
    @Binding var retreivedAllContent: Bool
    var loadMore: () -> Void
    
    var body: some View {
        HStack {
            if loadingContent && !retreivedAllContent && !showingError {
                ProgressView()
                    .progressViewStyle(YTSProgressViewStyle())
                    .padding()
            } else if !retreivedAllContent {
                Button(action: {
                    loadMore()
                }) {
                    VStack {
                        Spacer()
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "ellipsis")
                                .foregroundColor(colorScheme == .light
                                                 ? .shragaBlue
                                                 : .shragaGold)
                            Spacer()
                        }
                        Spacer()
                        Spacer()
                    }
                }
                .buttonStyle(BackZStackButtonStyle(backgroundColor: .cardViewBG))
                .cornerRadius(UI.cornerRadius)
                .shadow(radius: UI.shadowRadius)
            } else {
                Spacer()
            }
        }
    }
}

struct AutoLoadMoreBar_Previews: PreviewProvider {
    static var previews: some View {
        AutoLoadMoreBar(loadingContent: .constant(false), showingError: .constant(false), retreivedAllContent: .constant(false), loadMore: {})
    }
}
