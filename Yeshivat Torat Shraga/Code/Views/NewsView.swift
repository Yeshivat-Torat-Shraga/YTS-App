//
//  NewsView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 10/12/2021.
//

import SwiftUI

struct NewsView: View {
    @ObservedObject var model = NewsModel()
    var body: some View {
        NavigationView {
            ScrollView {
                if let articles = model.articles {
                    ForEach(articles) { article in
                        NavigationLink(destination: NewsArticleView(article)) {
                            NewsArticleCardView(article)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("YTS News")
        }
        .alert(isPresented: Binding(get: {
            model.showError
        }, set: {
            model.showError = $0
        }), content: {
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

struct NewsView_Previews: PreviewProvider {
    static var previews: some View {
        NewsView()
    }
}
