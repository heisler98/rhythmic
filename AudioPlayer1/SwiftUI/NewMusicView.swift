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
    @GestureState private var tapping: Bool = false
    var body: some View {
        VStack(alignment: .center) {
            header
            infoView
            library
        }
    }
    // MARK: - Header
    var header: some View {
        HStack {
            Text("Add music")
                .font(.title)
                .bold()
                .padding()
            Spacer()
            Button(action: { isPresented = false }) {
                Text("Done")
                    .bold()
            }.padding()
        }
    }
    // MARK: - Info
    var infoView: some View {
        VStack(alignment: .center) {
            Text("question")
                .font(.callout)
                .foregroundColor(.gray)
            Text("description")
                .font(.caption)
                .frame(maxWidth: 300)
                .multilineTextAlignment(TextAlignment.center)
            Button(action: {
                newMusicState.importFiles()
                isPresented = false
            }) {
                Text("Add File Sharing songs")
                    .font(.footnote)
                    .foregroundColor(.blue)
                    .padding()
            }
        }
    }
    // MARK: - Library
    var library: some View {
        List {
            ForEach(newMusicState.songs, id: \.self) { song in
                HStack {
                    if let title = song.title {
                        Text(title)
                            .foregroundColor(.blue)
                    } else {
                        Text("Unnamed Track")
                            .foregroundColor(.blue)
                    }
                    Spacer()
                    if let artist = song.artist {
                        Text(artist)
                            .foregroundColor(.gray)
                    } else {
                        Text("Unnamed Artist")
                            .foregroundColor(.gray)
                    }
                }.contentShape(Rectangle())
                .gesture(TapGesture().updating($tapping, body: { (_, state, transaction) in
                    state = tapping
                }).onEnded({ (_) in
                    newMusicState.import(song)
                }))
            }
        }
    }
}

struct NewMusicView_Previews: PreviewProvider {
    static var previews: some View {
        NewMusicView(newMusicState: NewMusicState(), isPresented: .constant(true))
    }
}
