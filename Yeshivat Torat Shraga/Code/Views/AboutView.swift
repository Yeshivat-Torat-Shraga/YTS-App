//
//  AboutView.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 5/11/22.
//

import SwiftUI
import MessageUI

struct Developer: Hashable {
    let name: String
    let githubURL: String
    let emailAddress: String
    let uuid = UUID()
}

struct AboutView: View {
    @Environment(\.colorScheme) var colorScheme
    let developers: [Developer]
    
    var miniPlayerShowing: Binding<Bool>
    
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    
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
        ScrollView {
            Group {
                VStack {
                    Text("""
                 This app was written by Torat Shraga 2022 alumni Benji Tusk and David Reese. Benji Tusk is now a student in Machon Lev, Jerusalem College of Technology, studying Computer Science, and is set to graduate in 2025. David Reese going to be learning in Yeshiva University and studying computer science, set to graduate in 2026.
                 """)
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
                                    sendEmail(to: developer.emailAddress)
                                }) {
                                    Image(systemName: "envelope")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 18, height: 18)
                                        .foregroundColor(.primary)
                                }
                                .buttonStyle(iOS14BorderedButtonStyle(color: .white))
                                .shadow(radius: UI.shadowRadius)
                                
                                Button(action: {
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
                    Button(action: {
                        let link = URL(string: "https://toratshraga.com")!
                        UIApplication.shared.open(link)
                    }) {
                        HStack {
                            Spacer()
                            Image(systemName: "safari")
                                .resizable()
                                .frame(width: 30, height: 30)
                            Text("Visit the YTS Website")
                                .font(.callout)
                                .foregroundColor(Color(UIColor.gray))
                            Spacer()
                        }
                    }
                    .buttonStyle(iOS14BorderedButtonStyle(color: .white))
                    
                    Button(action: {
                        let link = URL(string: "https://www.facebook.com/toratshraga/")!
                        UIApplication.shared.open(link)
                    }) {
                        HStack {
                            Spacer()
                            Image("facebook")
                                .resizable()
                                .frame(width: 30, height: 30)
                            Text("See YTS on Facebook")
                                .font(.callout)
                                .foregroundColor(Color(UIColor.gray))
                            Spacer()
                        }
                    }
                    .buttonStyle(iOS14BorderedButtonStyle(color: .white))
                    
                    Button(action: {
                        let link = URL(string: "https://www.instagram.com/toratshraga/")!
                        UIApplication.shared.open(link)
                    }) {
                        HStack {
                            Spacer()
                            Image("instagram")
                                .resizable()
                                .frame(width: 30, height: 30)
                            Text("See YTS on Instagram")
                                .font(.callout)
                                .foregroundColor(Color(UIColor.gray))
                            Spacer()
                        }
                    }
                    .buttonStyle(iOS14BorderedButtonStyle(color: .white))
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
            
            Spacer()
            
            Group {
                VStack {
                    Button(action: {
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
                                .foregroundColor(Color(UIColor.gray))
                            Spacer()
                        }
                    }
                    .buttonStyle(iOS14BorderedButtonStyle(color: .white))
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
            
            if let version = self.version, let build = build {
                Spacer()
                
                Group {
                    Text("V\(version) (\(build))")
                        .font(Font.footnote)
                        .foregroundColor(Color.gray)
                }
            }
            
            Spacer()
            
            if miniPlayerShowing.wrappedValue {
                Spacer().frame(height: UI.playerBarHeight)
            }
        }
        .padding(.horizontal)
        .navigationTitle("About")
        .navigationBarItems(trailing: LogoView(size: .small))
    }
    
    func sendEmail(to address: String) {
        if let url = URL(string: "mailto:\(address)") {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url)
            } else {
                UIApplication.shared.openURL(url)
            }
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
        AboutView(miniPlayerShowing: .constant(false))
            .preferredColorScheme(.dark)
    }
}
