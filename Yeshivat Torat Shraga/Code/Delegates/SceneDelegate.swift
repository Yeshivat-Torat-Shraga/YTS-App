//
//  SceneDelegate.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/9/21.
//

import UIKit
import SwiftUI
import FirebaseDynamicLinks

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    @ObservedObject var FavoritesManager = Favorites()
    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        var sourceURL: URL? = nil
        
        if let url = connectionOptions.userActivities.first?.webpageURL {
            sourceURL = url
        }
        // Get the managed object context from the shared persistent container.
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

        // Create the SwiftUI view and set the context as the value for the managedObjectContext environment keyPath.
        // Add `@Environment(\.managedObjectContext)` in the views that will need the context.
        let rootModel = RootModel(FavoritesManager)
        let contentView = RootView(model: rootModel).environment(\.managedObjectContext, context).environmentObject(FavoritesManager)

        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
        
        if let incomingURL = sourceURL {
            print("Incoming URL is \(incomingURL)")
            let _ = DynamicLinks.dynamicLinks().handleUniversalLink(incomingURL) { dynamicLink, error in
                guard error == nil, let dynamicLink = dynamicLink, let url = dynamicLink.url else {
                    print("Error: \(error!.localizedDescription) (U01C)")
                    return
                }
                
                guard let components = url.query?.components(separatedBy: "=") else {
                    print("Error: Could not read query in URL. (U03C)")
                    return
                }
                guard let idIndex = components.firstIndex(of: "id") else {
                    print("Error: Could not find query paramater 'id' in URL. (U02C)")
                    return
                }
                
                guard components.count > idIndex.magnitude + 1 else {
                    print("Error: No id found in URL query. (U04C)")
                    return
                }
                
                let contentID = components[idIndex.advanced(by: 1)]
                
                print("Linking to content id \(contentID)...")
                self.show(contentID)
            }
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        if let incomingURL = userActivity.webpageURL {
            print("Incoming URL is \(incomingURL)")
            let _ = DynamicLinks.dynamicLinks().handleUniversalLink(incomingURL) { dynamicLink, error in
                guard error == nil, let dynamicLink = dynamicLink, let url = dynamicLink.url else {
                    print("Error: \(error!.localizedDescription) (U01C)")
                    return
                }
                
                guard let components = url.query?.components(separatedBy: "=") else {
                    print("Error: Could not read query in URL. (U03C)")
                    return
                }
                guard let idIndex = components.firstIndex(of: "id") else {
                    print("Error: Could not find query paramater 'id' in URL. (U02C)")
                    return
                }
                
                guard components.count > idIndex.magnitude + 1 else {
                    print("Error: No id found in URL query. (U04C)")
                    return
                }
                
                let contentID = components[idIndex.advanced(by: 1)]
                
                print("Linking to content id \(contentID)...")
                self.show(contentID)
            }
        }
    }
    func show(_ contentID: String) {
        let group = DispatchGroup()
        var content: SortableYTSContent?
        group.enter()
        FirebaseConnection.loadContentByIDs([contentID]) { result, error in
            if let result = result?.first{
                content = result
            }
            group.leave()
        }
        group.enter()
        self.FavoritesManager.loadFavorites(completion: {_,_ in group.leave()})
        group.notify(queue: .main) {
            if let audio = content?.audio {
                RootModel.audioPlayer.play(audio: audio)
                let vc = UIHostingController(rootView: RootModel.audioPlayer.environmentObject(self.FavoritesManager))
                self.window?.rootViewController?.present(vc, animated: true)
                //                                }  else if let video = content?.video {
                //                                    let vc = UIHostingController(rootView: Text("Detected unsupported video content"))
                //                                    self.window?.rootViewController?.present(vc, animated: true)
            } else {
                let alert = UIAlertController(title: "An error occured", message: "The linked content could not be loaded", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .destructive, handler: nil))
                self.window?.rootViewController?.present(alert, animated: true)
                return
            }
        }
    }
}

