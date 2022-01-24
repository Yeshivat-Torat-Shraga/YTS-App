//
//  AppDelegate.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/9/21.
//

import UIKit
import CoreData
import Firebase
import FirebaseStorage
import AVKit
import FirebaseAppCheck

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let providerFactory: AppCheckProviderFactory
                
        #if targetEnvironment(simulator)
                providerFactory = AppCheckDebugProviderFactory()
        #else
                providerFactory = YTSAppCheckProviderFactory()
        #endif
                
        AppCheck.setAppCheckProviderFactory(providerFactory)
        
        FirebaseApp.configure()
        #if EMULATORS
        print("""
        *************************************
        **      +  === = === = ===  +      **
        **      |  USING EMULATORS  |      **
        **      +  === = === = ===  +      **
        *************************************
        """)
        Functions.functions().useEmulator(withHost: "http://localhost", port: 5001)
        #endif
        
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(AVAudioSession.Category.playback)
        } catch  {
            print("Audio session failed")
        }
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let sendingAppID = options[.sourceApplication]
        print("source application = \(sendingAppID ?? "Unknown")")
        
        // Process the URL.
            guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true), let albumPath = components.path, let params = components.queryItems else {
                    print("Invalid URL or album path missing")
                    return false
            }

        print(url)
        return false
//            if let photoIndex = params.first(where: { $0.name == "index" })?.value {
//                print("albumPath = \(albumPath)")
//                print("photoIndex = \(photoIndex)")
//                return true
//            } else {
//                print("Photo index missing")
//                return false
//            }
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Yeshivat_Torat_Shraga")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

#if EMULATORS
    func applicationWillTerminate(_ application: UIApplication) {
        print("""
        *************************************
        **      +  === = === = ===  +      **
        **      |  USING EMULATORS  |      **
        **      +  === = === = ===  +      **
        *************************************
        """)
    }
#endif
    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

