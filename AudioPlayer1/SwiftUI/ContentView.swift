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
    @State private var showAddMusicSheet: Bool = false
    @ObservedObject var appState: AppState
    var interactor: Interactor
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            controlView
                .padding(.vertical)
                .padding(.bottom, 10)
                .animation(.easeInOut)
            library
            
        }.sheet(isPresented: $showAddMusicSheet) {
            NewMusicView(newMusicState: appState.newMusicState, isPresented: $showAddMusicSheet)
        }
    }
    
    // MARK: - Control view
    var controlView: some View {
        VStack(alignment: .center, spacing: 15) {
            Text(appState.playingTrack?.title ?? "Not Playing")
                .font(.headline)
                .animation(.linear)
                .transition(.opacity)
            
            HStack(alignment: .center, spacing: 50) {
                Button(action: {
                    interactor.rewind()
                }) {
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
                        LinearGradient(gradient: Gradient(colors: [.green, .blue, .purple]), startPoint: .topLeading, endPoint: .topTrailing)
                            .mask(Image(systemName:"play.fill")
                                    .resizable()
                                    .scaledToFit())
                            .aspectRatio(contentMode: .fit)
                            .transition(.opacity)
                    } else {
                        LinearGradient(gradient: Gradient(colors: [.green, .blue, .purple]), startPoint: .topLeading, endPoint: .topTrailing)
                            .mask(Image(systemName:"pause.fill")
                                    .resizable()
                                    .scaledToFit())
                            .aspectRatio(contentMode: .fit)
                            .transition(.opacity)
                    }
                }.frame(maxWidth: 34)
                Button(action: {
                    interactor.skip()
                }) {
                    LinearGradient(gradient: Gradient(colors: [.red, .yellow, .orange, .green, .blue, .purple].reversed()), startPoint: .topLeading, endPoint: .topTrailing)
                        .mask(Image(systemName:"forward.fill")
                                .resizable()
                                .scaledToFit())
                        .aspectRatio(contentMode: .fit)
                    
                    
                }.frame(maxWidth: 44)
            }
        }
    }
    
    // MARK: - Library
    var library: some View {
        RoundedRectangle(cornerRadius: 35)
            .fill(Color.white)
            .shadow(radius: 10)
            .padding(.horizontal, 5)
            .overlay(
                List {
                    Section {
                        shuffleRow
                            .onTapGesture {
                                interactor.shuffle()
                            }
                        playAllRow
                            .onTapGesture {
                                interactor.playAll()
                            }
                        
                    }
                    Section(header: Text("Library")) {
                        ForEach(appState.tracks, id: \.title) { track in
                            HStack {
                                Text(track.title)
                                    .bold()
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                dLog("Selected \(track.title)")
                                interactor.play(track: track)
                            }
                        }
                        addMusicRow
                            .onTapGesture {
                                showAddMusicSheet = true
                            }
                    }
                }.modifier(ListModifier())
            )
    }
    
    // MARK: - Rows
    var shuffleRow: some View {
        HStack {
            Image(systemName: "shuffle")
            Text("Shuffle")
            Spacer()
        }.contentShape(Rectangle())
    }
    
    var playAllRow: some View {
        HStack {
            Image(systemName: "play.fill")
                .foregroundColor(.green)
                .padding(.trailing, 5)
            Text("Play All")
            Spacer()
        }.contentShape(Rectangle())
    }
    
    var addMusicRow: some View {
        HStack {
            Text("Find more music")
                .foregroundColor(.blue)
            Spacer()
        }.contentShape(Rectangle())
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
