//
//  AppState.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 8/13/20.
//  Copyright © 2020 Hunter Eisler. All rights reserved.
//

import Combine
/// A type for managing app state.
class AppState: ObservableObject {
    /// The view model of the app.
    var viewModel = ViewModel()
    /// A convenience getter for view model tracks.
    var tracks: [Track] {
        viewModel.sorter.resort(by: .DateAddedAscending)
        return viewModel.sorter.sorted.map { $1 }
    }
    /// Indicates the state of playback.
    @Published var playbackPaused: Bool = false
    @Published var playingTrack: Track? = nil
    
    var anyCancellable: [AnyCancellable?] = []
    
    func newTrack(at url: URL) {
        guard let bpm = TempoHandler.core.tempo(of: url, completion: nil) else {
            dLog("Could not get BPM")
            return
        }
        viewModel.buildTrack(url: url, periodOrBPM: bpm)
        DispatchQueue.main.sync { self.objectWillChange.send() }
    }
    
    deinit {
        anyCancellable.forEach { $0?.cancel() }
    }
}
