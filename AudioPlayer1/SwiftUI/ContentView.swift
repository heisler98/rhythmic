//
//  ContentView.swift
//  Shared
//
//  Created by Hunter Eisler on 8/6/20.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var largeTitle: Bool = false
    @ObservedObject var appState: AppState
    var interactor: Interactor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            controlView
                .padding(.vertical)
                .padding(.bottom, 10)
                .animation(.easeInOut)
            RoundedRectangle(cornerRadius: 35)
                .fill(Color.white)
                .shadow(radius: 10)
                .padding(.horizontal, 5)
                .overlay(
                    List {
                        Section {
                            shuffleRow
                            playAllRow
                        }
                        Section(header: Text("Library")) {
                            ForEach(appState.tracks, id: \.title) { track in
                                Text(track.title)
                                    .bold()
                                    .onTapGesture {
                                        dLog("Selected \(track.title)")
                                        interactor.play(track: track)
                                    }
                            }
                        }
                    }.modifier(ListModifier())
                )
            
            
        }
    }
    
    var controlView: some View {
        VStack(alignment: .center, spacing: 15) {
            Text(appState.playingTrack?.title ?? "Not Playing")
                .font((largeTitle) ? .title : .caption)
                .fontWeight(.bold)
                .animation(.easeIn)
            HStack(spacing: 0) {
                Text("3:00")
                    .font(.caption)
                    .padding(.leading, 5)
                Slider(value: .constant(0.5), in: 0...1)
                    .accentColor(.gray)
                    .padding(.horizontal)
                Text("-1:30")
                    .font(.caption)
                    .padding(.trailing, 5)
            }
            
            HStack(alignment: .center, spacing: 50) {
                Button(action: {}) {
                    LinearGradient(gradient: Gradient(colors: [.red, .yellow, .orange, .green, .blue, .purple]), startPoint: .topLeading, endPoint: .topTrailing)
                        .mask(Image(systemName:"backward.fill")
                                .resizable()
                                .scaledToFit())
                        .aspectRatio(contentMode: .fit)
                }.frame(maxWidth: 44)
                
                Button(action: {
                    interactor.pauseResume()
                }) {
                    if appState.playbackPaused {
                        Image(systemName: "play.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .transition(.opacity)
                    } else {
                        Image(systemName: "pause.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .transition(.opacity)
                    }
                }.frame(maxWidth: 34)
                Button(action: {}) {
                    LinearGradient(gradient: Gradient(colors: [.red, .yellow, .orange, .green, .blue, .purple]), startPoint: .topLeading, endPoint: .topTrailing)
                        .mask(Image(systemName:"forward.fill")
                                .resizable()
                                .scaledToFit())
                        .aspectRatio(contentMode: .fit)
                    
                    
                }.frame(maxWidth: 44)
            }
        }
    }
    
    var shuffleRow: some View {
        HStack {
            Image(systemName: "shuffle")
                
            Text("Shuffle")
        }
    }
    
    var playAllRow: some View {
        HStack {
            Image(systemName: "play.fill")
                .foregroundColor(.green)
            Text("Play All")
        }
    }
}

struct ExperimentalView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(appState: AppState(), interactor: Interactor(viewModel: ViewModel()))
    }
}

struct ListModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 14.0, *) {
            return AnyView(content.listStyle(InsetGroupedListStyle()))
        } else {
            return AnyView(content.listStyle(GroupedListStyle()))
        }
    }
}
