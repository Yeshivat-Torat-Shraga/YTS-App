//
//  AboutView.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 5/11/22.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            Text("""
        This app was written by Torat Shraga alumni Benji Tusk and David Reese. Benji Tusk is now a student in Machon Lev, Jerusalem Collage of Technology, studying Computer Science, and is set to graduate in 2025. David Reese is studying __FieldOfStudy__ in Yeshiva University, to graduate in 20XX. David specializes in __SpecialSkills__, having worked on __PreviousProjects__ in the past. Benji has experience with a, b, c, and hopes to get a job doing __SomethingCool__.
        
        You can reach the developers here:
        • Benji Tusk: __MethodOfContact__
        • David Reese: __MethodOfContact__
        """)
            .padding()
            .foregroundColor(.shragaBlue)
            Spacer()
        }
        .navigationTitle("About")
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
