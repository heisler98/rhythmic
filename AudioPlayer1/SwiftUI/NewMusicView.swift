//
//  NewMusicView.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 9/8/20.
//  Copyright © 2020 Hunter Eisler. All rights reserved.
//

import SwiftUI
import MediaPlayer

struct NewMusicView: View {
    @ObservedObject var newMusicState: NewMusicState
    @Binding var isPresented: Bool
    var body: some View {
        VStack(alignment: .leading) {
            Text("Add music")
                .font(.title)
                .bold()
                .padding()
            List {
                ForEach(newMusicState.songs, id: \.self) { song in
                    HStack {
                        Text((song ).title ?? "Unnamed Track")
                        Spacer()
                        Text((song ).artist ?? "Unknown Artist")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
}

struct NewMusicView_Previews: PreviewProvider {
    static var previews: some View {
        NewMusicView(newMusicState: NewMusicState(), isPresented: .constant(true))
    }
}
