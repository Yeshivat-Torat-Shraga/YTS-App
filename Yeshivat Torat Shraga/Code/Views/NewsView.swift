//
//  NewsView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 10/12/2021.
//

import SwiftUI
import FirebaseAnalytics

struct NewsView: View {
    @ObservedObject var model = NewsModel()
    var miniPlayerShowing: Binding<Bool>
    @State var presentingSearchView = false
    
    init(miniPlayerShowing: Binding<Bool>) {
        self.miniPlayerShowing = miniPlayerShowing
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack {
                    if let articles = model.articles {
                        if articles.count > 0 {
                            ForEach(articles) { article in
                                NavigationLink(destination: NewsArticleView(article, miniPlayerShowing: miniPlayerShowing)) {
                                    NewsArticleCardView(article)
                                        .padding(.horizontal)
                                }
                                .simultaneousGesture(
                                    TapGesture()
                                        .onEnded {
                                            Haptics.shared.play(UI.Haptics.navLink)
                                            if article.isMostRecentArticle {
                                                @AppStorage("mostRecentArticleID") var mostRecentArticleID = ""
                                                mostRecentArticleID = article.id
                                                model.hasUnreadArticles = false
                                            }
                                        })
                            }
                            LoadMoreBar(
                                loadingContent: Binding(get: {
                                    model.loadingArticles
                                }, set: {
                                    model.loadingArticles = $0
                                }),
                                showingError: Binding(get: {
                                    model.showError
                                }, set: {
                                    model.showError = $0
                                }),
                                retreivedAllContent: Binding(get: {
                                    model.loadedAllArticles
                                }, set: {
                                    model.loadedAllArticles = $0
                                }),
                                loadMore: {
                                    model.load()
                                })
                        } else {
                            VStack {
                                Text("No news articles have been posted yet.")
                                    .bold()
                                    .multilineTextAlignment(.center)
                                    .font(.title2)
                                    .padding(.vertical)
                                Text("Check again in a little bit.")
                            }
                            .padding(.vertical)
                            
                        }
                    }
                    
                    if model.loadingArticles {
                        ProgressView()
                            .progressViewStyle(YTSProgressViewStyle())
                    }
                    
                    if miniPlayerShowing.wrappedValue {
                        Spacer().frame(height: UI.playerBarHeight)
                    }
                }
            }
            .navigationTitle("Torah & News")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    LogoView(size: .small)
                }
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button(action: {
//                        self.presentingSearchView = true
//                    }) {
//                        Image(systemName: "magnifyingglass").foregroundColor(.shragaBlue)
//                    }
//                }
            }
        }
        .onAppear {
            Analytics.logEvent("opened_view", parameters: [
                "page_name": "News"
            ])
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
        .sheet(isPresented: $presentingSearchView) {
            SearchView()
                .background(BackgroundClearView())
        }
    }
}

struct NewsView_Previews: PreviewProvider {
    static var previews: some View {
        NewsView(miniPlayerShowing: .constant(false))
    }
}
