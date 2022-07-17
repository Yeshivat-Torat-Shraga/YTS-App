//
//  AboutView.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 5/11/22.
//

import SwiftUI
import MessageUI
import FirebaseAnalytics
import FirebaseMessaging

struct Developer: Hashable {
    let name: String
    let githubURL: String
    let emailAddress: String
    let uuid = UUID()
}

struct AboutView: View {
    @Environment(\.colorScheme) var colorScheme
    @State var showSecretMessage: Bool = false
    @AppStorage("showDeveloperSettings") private var showDevSettings = false
    @AppStorage("enableDevNotifications") var devNotificationsEnabled: Bool = false
    
    
    let developers: [Developer]
    var miniPlayerShowing: Binding<Bool>
    
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    
    let description: String = """
                 This app was written by 2022 Torat Shraga alumni Benji Tusk and David Reese. Benji Tusk went to Machon Lev, Jerusalem College of Technology, studying Computer Science, and is set to graduate in 2025. David Reese went to Yeshiva University to learn in the Mazer Yeshiva Program and to study science.
                 """
    
    init(miniPlayerShowing: Binding<Bool>) {
        self.developers = [
            Developer(name: "Benji Tusk",
                      githubURL: "https://github.com/benjitusk",
                      emailAddress: "benjitusk1@gmail.com"),
            Developer(name: "David Reese",
                      githubURL: "https://github.com/davidreese",
                      emailAddress: "david@reesedevelopment.com"),
        ]
        
        self.miniPlayerShowing = miniPlayerShowing
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            Group {
                VStack {
                    Text(description)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding()
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    VStack {
                        ForEach(developers, id: \.uuid) { developer in
                            HStack {
                                //                                Spacer()
                                Text("Contact \(developer.name):")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                Spacer()
                                Button(action: {
                                    Analytics.logEvent("developer_email_button", parameters: [
                                        "developer": developer.name
                                    ])
                                    sendEmail(to: developer.emailAddress)
                                }) {
                                    Image(systemName: "envelope")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 18, height: 18)
                                        .foregroundColor(.black)
                                }
                                .buttonStyle(iOS14BorderedButtonStyle(color: .white))
                                .shadow(radius: UI.shadowRadius)
                                
                                Button(action: {
                                    Analytics.logEvent("developer_github_button", parameters: [
                                        "developer": developer.name
                                    ])
                                    let link = URL(string: developer.githubURL)!
                                    UIApplication.shared.open(link)
                                }) {
                                    Image("github")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 18, height: 18)
                                }
                                .buttonStyle(iOS14BorderedButtonStyle(color: .white))
                                .shadow(radius: UI.shadowRadius)
                            }
                            .padding()
                            .padding(.horizontal)
                        }
                        .background(Color(hex: 0x80A44C))
                        .cornerRadius(UI.cornerRadius)
                        .shadow(radius: UI.shadowRadius)
                    }
                    
                }
                .padding()
                .background(UI.cardBlueGradient
                    .overlay(Rectangle().fill(colorScheme == .light
                                              ? Color.white
                                              : Color.black).opacity(0.2))
                )
            }
            .cornerRadius(UI.cornerRadius)
            .shadow(radius: UI.shadowRadius)
            .padding(.bottom)
            
            Group {
                VStack {
                    HStack {
                        Spacer()
                        Text("Visit Torat Shraga")
                            .font(.callout)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    HStack {
                        
                        Spacer()
                        Button(action: {
                            Analytics.logEvent("opened_shraga_webpresence", parameters: [
                                "destination": "website",
                            ])
                            let link = URL(string: "https://toratshraga.com")!
                            UIApplication.shared.open(link)
                        }) {
                            HStack {
                                Spacer()
                                Image(systemName: "safari")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.shragaBlue)
                                Spacer()
                            }
                        }
                        .buttonStyle(iOS14BorderedButtonStyle(color:.white))
                        .shadow(radius: UI.shadowRadius)
                        
                        Spacer()
                        Button(action: {
                            Analytics.logEvent("opened_shraga_webpresence", parameters: [
                                "destination": "instagram",
                            ])
                            
                            let link = URL(string: "https://www.instagram.com/toratshraga/")!
                            UIApplication.shared.open(link)
                        }) {
                            HStack {
                                Spacer()
                                Image("instagram")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                Spacer()
                            }
                        }
                        .buttonStyle(iOS14BorderedButtonStyle(color:.white))
                        .shadow(radius: UI.shadowRadius)
                        
                        
                        Spacer()
                        Button(action: {
                            Analytics.logEvent("opened_shraga_webpresence", parameters: [
                                "destination": "facebook",
                            ])
                            let link = URL(string: "https://www.facebook.com/toratshraga/")!
                            UIApplication.shared.open(link)
                        }) {
                            HStack {
                                Spacer()
                                Image("facebook")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                Spacer()
                            }
                        }
                        .buttonStyle(iOS14BorderedButtonStyle(color:.white))
                        .shadow(radius: UI.shadowRadius)
                        
                        Spacer()
                        
                    }
                }
                .padding()
                .background(UI.cardBlueGradient
                    .overlay(Rectangle().fill(colorScheme == .light
                                              ? Color.white
                                              : Color.black).opacity(0.2))
                )
            }
            .foregroundColor(.black)
            .cornerRadius(UI.cornerRadius)
            .shadow(radius: UI.shadowRadius)
            .padding(.bottom)
            
            Spacer()
            
            Group {
                VStack {
                    Button(action: {
                        Analytics.logEvent("opened_shraga_github", parameters: [:])
                        let link = URL(string: "https://github.com/Yeshivat-Torat-Shraga/YTS-App")!
                        UIApplication.shared.open(link)
                    }) {
                        HStack {
                            Spacer()
                            Image("github")
                                .resizable()
                                .frame(width: 30, height: 30)
                            Text("YTS Source Code on Github")
                                .font(.callout)
                            Spacer()
                        }
                    }
                    .buttonStyle(iOS14BorderedButtonStyle(color: .white))
                    .shadow(radius: UI.shadowRadius)
                    
                }
                .padding()
                .background(UI.cardBlueGradient
                    .overlay(Rectangle().fill(colorScheme == .light
                                              ? Color.white
                                              : Color.black).opacity(0.2))
                )
                .shadow(radius: UI.shadowRadius)
            }
            .foregroundColor(.black)
            .cornerRadius(UI.cornerRadius)
            .shadow(radius: UI.shadowRadius)
            
            
            if let version = self.version, let build = build {
                HStack {
                    Spacer()
                    Group {
                        if showDevSettings {
                            Text("v\(version) (\(build))")
                                .bold()
                                .foregroundLinearGradient(colors: colorScheme == .light ? [.blue, .shragaBlue] : [.yellow, .shragaGold], startPoint: .leading, endPoint: .trailing)
                        } else {
                            Text("v\(version) (\(build))")
                                .foregroundColor(.gray)
                            
                        }
                    }
                    .font(.footnote)
                    .onTapGesture(count: 5) {
                        showSecretMessage = true
                        Analytics.logEvent("triggered_versionnumber_alert", parameters: [
                            "version_number": "v\(version) (\(build))"
                        ])
                    }
                }
            }
            
            if miniPlayerShowing.wrappedValue {
                Spacer().frame(height: UI.playerBarHeight)
            }
        }
        .onAppear {
            Analytics.logEvent("opened_view", parameters: [
                "page_name": "About"
            ])
        }
        .padding(.horizontal)
        .navigationTitle("About")
        .navigationBarItems(trailing: LogoView(size: .small))
        .alert(isPresented: $showSecretMessage) {
            Alert(title: Text("Developer Settings"),
                  message: Text("Are you sure you want to \(showDevSettings == false ? "enable" : "disable") developer settings?"),
                  primaryButton: .cancel(Text("No, thanks")),
                  secondaryButton: .destructive(Text("\(showDevSettings == false ? "Enable" : "Disable") developer settings")) {
                showDevSettings.toggle()
                if showDevSettings == false {
                    Messaging.messaging().unsubscribe(fromTopic: "debug")
                    devNotificationsEnabled = false
                    
                }
            }
                  
            )
            
        }
    }
    
    func sendEmail(to address: String) {
        if let url = URL(string: "mailto:\(address)") {
            UIApplication.shared.open(url)
        }
        //        if MFMailComposeViewController.canSendMail() {
        //                let mail = MFMailComposeViewController()
        //                mail.mailComposeDelegate = self
        //                mail.setToRecipients([address])
        //
        //                present(mail, animated: true)
        //            } else {
        //                // show failure alert
        //            }
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AboutView(miniPlayerShowing: .constant(false))
                .preferredColorScheme(.dark)
        }
    }
}

extension Text {
    public func foregroundLinearGradient(
        colors: [Color],
        startPoint: UnitPoint,
        endPoint: UnitPoint) -> some View
    {
        self.overlay (
            
            LinearGradient(
                colors: colors,
                startPoint: startPoint,
                endPoint: endPoint
            )
            .mask(
                self
                
            )
        )
    }
}
