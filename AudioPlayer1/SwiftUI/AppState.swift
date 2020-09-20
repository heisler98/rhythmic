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
    @Published var viewModel = ViewModel()
    /// A convenience getter for view model tracks.
    var tracks: [Track] {
        viewModel.sorter.resort(by: .DateAddedAscending)
        return viewModel.sorter.sorted.map { $1 }
    }
    /// A reference to the new music state.
    var newMusicState: NewMusicState!
    /// Indicates the state of playback.
    @Published var playbackPaused: Bool = false
    /// The current track playing, or `nil` if none is playing.
    @Published var playingTrack: Track? = nil
    /// A state indicating whether the activity indicator should show.
    @Published var showActivityIndicator: Bool = false
    /// A collection of subscribers.
    var anyCancellable: [AnyCancellable?] = []
    
    // MARK: - Track management
    /// Crafts a new track at the given URL.
    func newTrack(at url: URL) {
        guard let bpm = TempoHandler.core.tempo(of: url, completion: nil) else {
            dLog("Could not get BPM")
            return
        }
        viewModel.buildTrack(url: url, periodOrBPM: bpm)
        DispatchQueue.main.sync {
            self.objectWillChange.send()
            self.showActivityIndicator = false
        }
    }
    /// Removes the tracks at the specified offsets.
    func removeTracks(at offsets: IndexSet) {
        offsets.forEach { _ = viewModel.removeTrack(at: $0) }
        self.objectWillChange.send()
    }
    
    deinit {
        anyCancellable.forEach { $0?.cancel() }
    }
}
