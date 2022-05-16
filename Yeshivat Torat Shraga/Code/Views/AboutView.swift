//
//  AboutView.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 5/11/22.
//

import SwiftUI
import MessageUI

struct AboutView: View {
    @EnvironmentObject var audioPlayerModel: AudioPlayerModel
    
    var body: some View {
        ScrollView {
            Group {
            VStack {
                Text("""
                 This app was written by Torat Shraga alumni Benji Tusk and David Reese. Benji Tusk is now a student in Machon Lev, Jerusalem College of Technology, studying Computer Science, and is set to graduate in 2025. David Reese going to be learning in Yeshiva University and studying computer science, set to graduate in 2026.
                 """)
                .padding()
                .font(.body)
                .foregroundColor(.black)
                
                Divider()
                
                Group {
                HStack {
//                    Label("Benji", systemImage: "person.crop.circle")
                    Text("Contact Benji:")
                        .font(Font.subheadline)
                    Button {
                        sendEmail(to: "benjitusk1@gmail.com")
                    } label: {
                        Image(systemName: "envelope")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 18, height: 18)
                    }
                    .buttonStyle(iOS14BorderedButtonStyle(color: .white))
                    Button {
                        let link = URL(string: "https://github.com/benjitusk")!
                        UIApplication.shared.open(link)
                    } label: {
                        Image("github")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 18, height: 18)
                    }
                    .buttonStyle(iOS14BorderedButtonStyle(color: .white))
                }
                .padding()
                .frame(minWidth: 236)
                }
                .foregroundColor(.black)
                .background(Color(UIColor.systemGray4))
                .cornerRadius(UI.cornerRadius)
                .shadow(radius: UI.shadowRadius)
                
                
                Group {
                HStack {
                    Text("Contact David:")
                        .font(Font.subheadline)
                    Button {
                        sendEmail(to: "david@reesedevelopment.com")
                    } label: {
                        Image(systemName: "envelope")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 18, height: 18)
                    }
                    .buttonStyle(iOS14BorderedButtonStyle(color: .white))
                    Button {
                        let link = URL(string: "https://github.com/davidreese")!
                        UIApplication.shared.open(link)
                    } label: {
                        Image("github")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 18, height: 18)
                    }
                    .buttonStyle(iOS14BorderedButtonStyle(color: .white))
                }
                .padding()
                .frame(minWidth: 236)
                }
                .foregroundColor(.black)
                .background(Color(UIColor.systemGray4))
                .cornerRadius(UI.cornerRadius)
                .shadow(radius: UI.shadowRadius)
                
            }
            .padding()
            .background(Color.shragaBlue)
//            .background(Color(UIColor.systemGray4))
            }
            .cornerRadius(UI.cornerRadius)
            .shadow(radius: UI.shadowRadius)
            .padding([.horizontal, .bottom])
            
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
            .background(Color.shragaBlue)
//            .background(Color(UIColor.systemGray4))
            }
            .cornerRadius(UI.cornerRadius)
            .shadow(radius: UI.shadowRadius)
            .padding()
        
            Spacer()
            
            if audioPlayerModel.audio != nil {
                Spacer().frame(height: UI.playerBarHeight)
            }
        }
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
        AboutView()
    }
}
