//
//  NewsView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 10/12/2021.
//

import SwiftUI
import Shimmer

struct NewsView: View {
    @ObservedObject var model = NewsModel()
    var body: some View {
        NavigationView {
            ScrollView {
                if let articles = model.articles, articles.count > 0 {
                    ForEach(articles) { article in
                        NavigationLink(destination: NewsArticleView(article)) {
                            NewsArticleCardView(article)
                                .padding(.horizontal)
                        }
                        .simultaneousGesture(
                            TapGesture()
                                .onEnded {
                                    Haptics.shared.play(UI.Haptics.navLink)
                                })
                    }
                } else {
                    ForEach(0..<4, id: \.self) { _ in
                        NewsArticleCardView(.sample)
                    }
                    .shadow(radius: UI.shadowRadius)
                    .redacted(reason: .placeholder)
                    .shimmering()
                    .padding(.horizontal)
                }
            }
            .navigationTitle(Text("News"))
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
        .onDidAppear {
            model.loadOnlyIfNeeded()
        }
    }
}

struct NewsView_Previews: PreviewProvider {
    static var previews: some View {
        NewsView()
    }
}
