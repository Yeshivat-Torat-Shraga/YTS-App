//
//  UI.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/11/21.
//

import SwiftUI

/// Source: https://stackoverflow.com/questions/56760335/round-specific-corners-swiftui
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

/// Source: https://stackoverflow.com/questions/56760335/round-specific-corners-swiftui
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

/// Source: https://stackoverflow.com/questions/56610957/is-there-a-method-to-blur-a-background-in-swiftui
struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView { UIVisualEffectView() }
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) { uiView.effect = effect }
}

/// Source: https://stackoverflow.com/questions/56610957/is-there-a-method-to-blur-a-background-in-swiftui
struct Blur: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemMaterial
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

class AsyncImageLoader: ObservableObject {
    @Published var downloadedImage: UIImage?
    private var task: URLSessionDataTask?
    @Published var isReady: Bool = false
    
//    let didChange = PassthroughSubject<AsyncImageLoader?, Never>()
    
    init() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { _ in
            self.isReady = (self.downloadedImage != nil)
        })
    }
    
    func suspend() {
        if let task = task {
            task.suspend()
        } else {
            print("AsyncImageLoader: Failed to suspend task, it is nil.")
        }
    }
    
    func resume() {
        if let task = task {
            task.resume()
        } else {
            print("AsyncImageLoader: Failed to resume task, it is nil.")
        }
    }
    
    func prepare(url: String, completion: ((_ image: Image?) -> Void)? = nil) {
        guard let imageURL = URL(string: url) else {
            fatalError("ImageURL '\(url)' is not valid.")
        }
        
        prepare(url: imageURL, completion: completion)
    }
    
    func prepare(url imageURL: URL, completion: ((_ image: Image?) -> Void)? = nil) {
        let task = URLSession.shared.dataTask(with: imageURL) { data, response, error in
            
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
//                     self.didChange.send(nil)
                }
                completion?(nil)
                return
            }
            
            
            DispatchQueue.main.async {
                self.downloadedImage = UIImage(data: data)
                if self.downloadedImage != nil {
                    completion?(Image(uiImage: self.downloadedImage!))
                    self.objectWillChange.send()
                } else {
                    completion?(nil)
                }
//                self.didChange.send(self)
            }
            
        }
        
        self.task = task
        
//        task.resume()
    }
}

protocol URLImageable {
    var image: Image? { get set }
    var imageURL: URL? { get }
}

struct DownloadableImage<Object: URLImageable>: View {
    @ObservedObject private var model: DownloadableImageModel<Object>
    
    init(object: Object) {
        self.model = DownloadableImageModel(object: object)
    }
    
    var body: some View {
        if let image = model.object.image {
            image
                .resizable()
        } else if let imageURL = model.object.imageURL {
            URLImage(url: imageURL, placeholder: {
                ProgressView()
            }, completion: { image in
                model.object.image = image
            })
        } else {
            
        }
    }
    
    private class DownloadableImageModel<Object: URLImageable>: ObservableObject {
        @Published var object: Object
        
        init(object: Object) {
            self.object = object
        }
    }
}

struct URLImage<Content : View>: View {
    @ObservedObject var imageLoader = AsyncImageLoader()
    var placeholder: Content
    
    init(url: String, @ViewBuilder placeholder: @escaping () -> Content, completion: ((_ image: Image?) -> Void)? = nil) {
        self.placeholder = placeholder()
        self.imageLoader.prepare(url: url, completion: completion)
        self.imageLoader.resume()
    }
    
    init(url: URL, @ViewBuilder placeholder: @escaping () -> Content, completion: ((_ image: Image?) -> Void)? = nil) {
        self.placeholder = placeholder()
        self.imageLoader.prepare(url: url, completion: completion)
        self.imageLoader.resume()
    }
    
    var body: some View {
        VStack {
            if let uiImage = self.imageLoader.downloadedImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .background(Color.gray)
            } else {
//                AngularGradient(colors: [.gray.lighter(), UI.Constants.primaryColor], center: .bottomTrailing)
                Blur()
                    .overlay(
                placeholder
                    .clipped()
                    .onAppear {
                        imageLoader.resume()
                    }
                    .onDisappear {
                        imageLoader.suspend()
                    }
                )
            }
        }
    }
}
