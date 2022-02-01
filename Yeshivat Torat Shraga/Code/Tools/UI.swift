//
//  UI.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/11/21.
//

import SwiftUI

struct UI {
    static let shadowRadius: CGFloat = 2
    static let cornerRadius: CGFloat = 8
    static let navLinkFeedback: UIImpactFeedbackGenerator.FeedbackStyle = .light
//    static var
}

struct iOS14BorderedProminentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color(hex: 0x526B98))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}


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

struct BackgroundClearView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
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

struct SingleAxisGeometryReader<Content: View>: View
{
    private struct SizeKey: PreferenceKey
    {
        static var defaultValue: CGFloat { 10 }
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat)
        {
            value = max(value, nextValue())
        }
    }

    @State private var size: CGFloat = SizeKey.defaultValue

    var axis: Axis
    var alignment: Alignment = .center
    let content: (CGFloat)->Content

    var body: some View
    {
        content(size)
            .frame(maxWidth:  axis == .horizontal ? .infinity : nil,
                   maxHeight: axis == .vertical   ? .infinity : nil,
                   alignment: alignment)
            .background(GeometryReader
            {
                proxy in
                Color.clear.preference(key: SizeKey.self, value: axis == .horizontal ? proxy.size.width : proxy.size.height)
            })
            .onPreferenceChange(SizeKey.self) { size = $0 }
    }
}

/// https://stackoverflow.com/a/68088712/13368672
/// Haptics.shared.play(.heavy)
/// Haptics.shared.play(.light)
/// Haptics.shared.play(.medium)
/// Haptics.shared.play(.rigid)
/// Haptics.shared.play(.soft)
/// 
/// Haptics.shared.notify(.error)
/// Haptics.shared.notify(.success)
/// Haptics.shared.notify(.warning)
class Haptics {
    static let shared = Haptics()
    
    private init() { }

    func play(_ feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: feedbackStyle).impactOccurred()
    }
    
    func notify(_ feedbackType: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(feedbackType)
    }
    
    func impact() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}


class SlideshowImage: Identifiable, URLImageable {
    var imageURL: URL?
    var id: UUID
    var downloadableImage: DownloadableImage<SlideshowImage>?
    var image: Image?
    var uploaded: Date
    var name: String?
    init(image: Image, name: String? = nil, uploaded: Date = Date(timeIntervalSince1970: 0)) {
        self.uploaded = uploaded
        self.image = image
        self.name = name
        self.id = UUID()
        applyImage()
    }
    
    init(url: URL, name: String? = nil, uploaded: Date = Date(timeIntervalSince1970: 0)) {
        self.uploaded = uploaded
        self.imageURL = url
        self.name = name
        self.id = UUID()
        applyImage()
    }
    
    func applyImage() {
        self.downloadableImage = DownloadableImage(object: self)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SlideshowImage, rhs: SlideshowImage) -> Bool {
        lhs.id == rhs.id
    }
    
//    var body: some View {
//        DownloadableImage(object: self)
//    }
}

protocol URLImageable {
    var image: Image? { get set }
    var imageURL: URL? { get }
}

struct ShragaFlameProgressStyle: ProgressViewStyle {

    func makeBody(configuration: Configuration) -> some View {
//        let fractionCompleted = configuration.fractionCompleted ?? 0

        return ZStack {
            Image("Shraga")
        }
    }
}

/// Image view that makes `URLImage` easier when the image is taken from a `URLImageable`
struct DownloadableImage<Object: URLImageable>: View {
    @ObservedObject private var model: DownloadableImageModel<Object>
    
    /// Standard intializer for `DownloadableImage`
    /// - Parameter object: `Object` to display image data from
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
            Image(systemName: "questionmark")
                .resizable()
        }
    }
    
    private class DownloadableImageModel<Object: URLImageable>: ObservableObject {
        @Published var object: Object
        
        init(object: Object) {
            self.object = object
        }
    }
}

//General Source: https://stackoverflow.com/questions/57688242/swiftui-how-to-change-the-placeholder-color-of-the-textfield
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
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

extension Color {
    var components: (red: CGFloat, green: CGFloat, blue: CGFloat, opacity: CGFloat) {
        #if canImport(UIKit)
        typealias NativeColor = UIColor
        #elseif canImport(AppKit)
        typealias NativeColor = NSColor
        #endif

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var o: CGFloat = 0

        guard NativeColor(self).getRed(&r, green: &g, blue: &b, alpha: &o) else {
            return (0, 0, 0, 0)
        }
        return (r, g, b, o)
    }
    
    func lighter(by percentage: CGFloat = 30.0) -> Color {
        return self.adjust(by: abs(percentage) )
    }

    func darker(by percentage: CGFloat = 30.0) -> Color {
        return self.adjust(by: -1 * abs(percentage) )
    }

    func adjust(by percentage: CGFloat = 30.0) -> Color {
        return Color(red: min(Double(self.components.red + percentage/100), 1.0),
                     green: min(Double(self.components.green + percentage/100), 1.0),
                     blue: min(Double(self.components.blue + percentage/100), 1.0),
                     opacity: Double(self.components.opacity))
    }
}

extension View {
// This function changes our View to UIView, then calls another function
// to convert the newly-made UIView to a UIImage.
    public func asUIImage() -> UIImage {
        let controller = UIHostingController(rootView: self)
        
        controller.view.frame = CGRect(x: 0, y: CGFloat(Int.max), width: 1, height: 1)
        UIApplication.shared.windows.first!.rootViewController?.view.addSubview(controller.view)
        
        let size = controller.sizeThatFits(in: UIScreen.main.bounds.size)
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.sizeToFit()
        
// here is the call to the function that converts UIView to UIImage: `.asUIImage()`
        let image = controller.view.asUIImage()
        controller.view.removeFromSuperview()
        return image
    }
    
    func snapshot() -> UIImage {
            let controller = UIHostingController(rootView: self.edgesIgnoringSafeArea(.all))
            let view = controller.view

            let targetSize = controller.view.intrinsicContentSize
            view?.bounds = CGRect(origin: .zero, size: targetSize)
            view?.backgroundColor = .clear

            let renderer = UIGraphicsImageRenderer(size: targetSize)

            return renderer.image { _ in
                view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
            }
        }
}

extension UIView {
// This is the function to convert UIView to UIImage
    public func asUIImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}
