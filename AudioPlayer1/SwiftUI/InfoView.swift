//
//  InfoView.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 9/18/20.
//  Copyright © 2020 Hunter Eisler. All rights reserved.
//

import SwiftUI

struct InfoView: View {
    var body: some View {
        ScrollView {
            Text(Licensing.essentiaLicense)
                .multilineTextAlignment(.leading)
                .padding(5)
        }
    }
}

fileprivate struct Licensing {
    static var essentiaLicense: String {
        let essentiaLicense = Bundle.main.path(forResource: "Essentia Licensing", ofType: "txt")
        guard let license = try? String(contentsOfFile: essentiaLicense ?? "") else {
            return ""
        }
        return license
    }
}
