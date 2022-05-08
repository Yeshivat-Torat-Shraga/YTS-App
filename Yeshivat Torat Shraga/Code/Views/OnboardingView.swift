//
//  OnboardingView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 28/02/2022.
//

import SwiftUI
import FirebaseMessaging

struct OnboardingView: View {
    var dismiss: (()->Void)?
    @State var notificationsHaveBeenSet: Bool = false
    let subtitleColor = Color(hex: 0xCCCCCC)
    var body: some View {
        ZStack {
            Color(hex: 0x212121).ignoresSafeArea()
            TabView {
                // MARK: Welcome
                VStack {
                    Image("Logo")
                        .resizable()
                        .foregroundColor(.shragaGold)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 250, height: 250)
                        .preferredColorScheme(.dark)
                        .padding()
                    
                    Text("Welcome to the YTS App.")
                        .font(.title)
                        .bold()
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .foregroundColor(.shragaGold)
                        .padding()
                        .padding(.horizontal)
                }
                // MARK: Favorites
                VStack {
                    Image(systemName: "bookmark")
                        .resizable()
                        .foregroundColor(.shragaGold)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150, height: 150)
                        .padding()
                    
                    Text("Favorite Shiurim")
                        .font(.title)
                        .bold()
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding()
                    
                    Text("Mark your favorite shiurim for quick access later on.")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.5)
                        .foregroundColor(subtitleColor)
                        .padding()
                        .padding(.horizontal)
                }
                
                // MARK: Images
                VStack {
                    Image(systemName: "photo")
                        .resizable()
                        .foregroundColor(.shragaGold)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150, height: 150)
                        .padding()
                    
                    Text("Featured Photos")
                        .font(.title)
                        .bold()
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding()
                    
                    Text("Check out the top photo picks from recent Shraga events and Tiyulim.")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.5)
                        .foregroundColor(subtitleColor)
                        .padding()
                        .padding(.horizontal)
                }
                // MARK: News
                VStack {
                    Image(systemName: "newspaper")
                        .resizable()
                        .foregroundColor(.shragaGold)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150, height: 150)
                        .padding()
                    
                    Text("News Updates")
                        .font(.title)
                        .bold()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding()
                    
                    Text("Stay up to date on the latest news at Yeshivat Torat Shraga.")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.5)
                        .foregroundColor(subtitleColor)
                        .padding()
                        .padding(.horizontal)
                }
                // MARK: Push Notifications
                VStack {
                    Spacer()
                    
                    Image(systemName: "bell")
                        .resizable()
                        .foregroundColor(.shragaGold)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150, height: 150)
                        .padding()
                    
                    Text("Push Notifications")
                        .font(.title)
                        .bold()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding()
                    
                    Text("Enable push notifications to stay up to date. This can be changed later in settings.")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.5)
                        .foregroundColor(subtitleColor)
                        .padding()
                        .padding(.horizontal)
                        .padding(.bottom)
                    
//                    Spacer()
                    
                    Button(action: {
                        // Show Notification prompt here
                        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
                        UNUserNotificationCenter.current().requestAuthorization(
                            options: authOptions,
                            completionHandler: { granted, error in
                                print(error as Any)
                                print(granted)
                            }
                        )
                        
                        UNUserNotificationCenter.current().getNotificationSettings { settings in
                            if settings.authorizationStatus == .authorized {
                                Messaging.messaging().subscribe(toTopic: "all") { error in
                                    if let error = error {
                                        print("\n\n\nError subscribing to notifications: \(error)\n\n\n")
                                    }
                                  print("Subscribed to all notifications successfuly")
                                }
                            }
                        }

                    }) {
                        Text("Enable Notifications")
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                    }
                    .padding()
                    .background(
                        Color(hex: 0x80A44C)
                            .cornerRadius(UI.cornerRadius)
                            .shadow(radius: UI.shadowRadius)
                    )
                    Spacer()
                }
                
                // MARK: Dismiss
                VStack {
                    Image(systemName: "arrow.right")
                        .resizable()
                        .foregroundColor(.shragaGold)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150, height: 150)
                        .padding()
                    
//                    Text("Enable push notifications to stay up to date.")
//                        .foregroundColor(subtitleColor)
//                        .padding()
//
                    
                    Button(action: {
                        dismiss?()
                    }) {
                        Text("Let's get started.")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                    }
                    .padding()
                    .background(
                        Color.shragaBlue
                            .cornerRadius(UI.cornerRadius)
                            .shadow(radius: UI.shadowRadius)
                    )
                }

            }
            .tabViewStyle(PageTabViewStyle())
        }
        .foregroundColor(.shragaBlue)
    }
}


struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
