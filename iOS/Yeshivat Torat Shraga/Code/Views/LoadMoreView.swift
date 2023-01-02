//
//  LoadMoreView.swift
//  Original Source: Kol Hatorah Kulah SwiftUI
//
//  Created by David Reese on 10/14/21.
//

import SwiftUI

/// View placed in a ScrollView for loading more content when it appears.
/// - Author: David Reese, sourced from the [Kol Hatorah Kulah App](https://github.com/davidreese/Kol-Hatorah-Kulah-SwiftUI).
struct LoadMoreView: View {
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
                    .padding(.bottom, 2)
            } else if !retreivedAllContent {
                EllipseButton(action: {
                    if !loadingContent {
                        loadMore()
                    }
                }, imageSystemName: "arrow.down", foregroundColor: .white, backgroundColor: Color("ShragaBlue"))
                    .padding()
                    .onAppear {
                        if !loadingContent && !showingError {
                            loadMore()
                            print("Calling 'loadMore' from LoadMoreView...")
                        }
                    }
            } else {
                Spacer()
            }
        }
    }
}

struct LoadMoreView_Previews: PreviewProvider {
    static var previews: some View {
        LoadMoreView(loadingContent: .constant(false), showingError: .constant(false), retreivedAllContent: .constant(false), loadMore: {})
    }
}
