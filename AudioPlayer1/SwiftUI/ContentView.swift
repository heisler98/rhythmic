//
//  ContentView.swift
//  Shared
//
//  Created by Hunter Eisler on 8/6/20.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var purchaseManager: IAPManager
    @EnvironmentObject var productManager: IAPManager.Products
    @State private var largeTitle: Bool = false
    @State private var showAddMusicSheet: Bool = false
    @State private var showInfoSheet: Bool = false
    @ObservedObject var appState: AppState
    var interactor: Interactor
    
    var body: some View {
        ZStack {
            VStack(alignment: .center, spacing: 0) {
                controlView
                    .padding(.vertical)
                    .padding(.bottom, 10)
                    .animation(.easeInOut)
                    .sheet(isPresented: $showInfoSheet) {
                        InfoView()
                    }
                library
                    .sheet(isPresented: $showAddMusicSheet) {
                        NewMusicView(newMusicState: appState.newMusicState, isPresented: $showAddMusicSheet)
                    }
            }
            
            
            if appState.showActivityIndicator {
                ProgressView("Adding song")
                    .progressViewStyle(CircularProgressViewStyle())
                    .transition(.opacity)
            }
        }
    }
    
    // MARK: - Control view
    var controlView: some View {
        VStack(alignment: .center, spacing: 15) {
            if let title = appState.playingTrack?.title {
                Text(title)
                    .font(.headline)
                    .animation(.linear)
                    .transition(.opacity)
            } else {
                Text("Not Playing")
                    .font(.headline)
                    .animation(.linear)
                    .transition(.opacity)
            }
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
                                //                                        .bold()
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
                        infoViewRow
                            .onTapGesture {
                                showInfoSheet = true
                            }
                    }
                }.listStyle(InsetGroupedListStyle())
            )
    }
    
    // MARK: - Rows
    var shuffleRow: some View {
        HStack {
            Image(systemName: "shuffle")
            Text("Shuffle")
                .bold()
            Spacer()
        }.contentShape(Rectangle())
    }
    
    var playAllRow: some View {
        HStack {
            Image(systemName: "play.fill")
                .foregroundColor(.green)
                .padding(.trailing, 5)
            Text("Play All")
                .bold()
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
    
    var infoViewRow: some View {
        HStack {
            Text("More info")
                .foregroundColor(.blue)
            Spacer()
        }.contentShape(Rectangle())
    }
}
