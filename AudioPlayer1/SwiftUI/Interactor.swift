//
//  Interactor.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 8/13/20.
//  Copyright © 2020 Hunter Eisler. All rights reserved.
//

import Combine

class Interactor: ObservableObject {
    /// The view model of the app.
    /// - note: This property is assigned by a subcriber attached to the `AppState.viewModel` publisher.
    var viewModel: ViewModel
    /// The collection of tracks, sorted date added ascending.
    var tracks: [Track] {
        viewModel.sorter.resort(by: .DateAddedAscending)
        return viewModel.sorter.sorted.map { $1 }
    }
    /// The current playback handler, or `nil` if playback is not active.
    var handler: PlaybackHandler?
    /// A subject which passes the `playbackPaused` Boolean from a playback handler.
    let playbackPaused = PassthroughSubject<Bool, Never>()
    /// A subject which passes the currently playing track to any subscribers.
    let playingTrack = PassthroughSubject<Track, Never>()
    
    // MARK: - Interactions
    /// Plays a track.
    func play(track: Track) {
        guard let index = viewModel.index(of: track) else { return }
        handler?.stopPlaying()
        viewModel.safeSelectCell(at: index)
        handler = try? viewModel.playbackHandler()
        handler?.startPlaying()
        viewModel.queue.reset()
        playingTrack.send(track)
        playbackPaused.send(false)
    }
    /// Plays a track at an index.
    func play(_ index: Int) {
        handler?.stopPlaying()
        viewModel.safeSelectCell(at: index)
        handler = try? viewModel.playbackHandler()
        handler?.startPlaying()
        viewModel.queue.reset()
        playingTrack.send(tracks[index])
        playbackPaused.send(false)
    }
    /// Toggles pause/resume.
    func pauseResume() {
        guard let handler = handler else { return }
        handler.pauseResume()
        playbackPaused.send(!handler.isPlaying)
    }
    /// Skips the currently playing track.
    func skip() {
        handler?.skip()
        playbackPaused.send(false)
    }
    /// Rewinds the currently playing track.
    func rewind() {
        handler?.rewind()
        playbackPaused.send(false)
    }
    /// Plays all the tracks.
    func playAll() {
        handler?.stopPlaying()
        handler = try? viewModel.playAll()
        handler?.startPlaying()
        viewModel.queue.reset()
        playingTrack.send(Track(title: "All Tracks", period: 0.5, fileName: "NO_NAME"))
        playbackPaused.send(false)
    }
    /// Plays all the tracks, in shuffled order.
    func shuffle() {
        handler?.stopPlaying()
        handler = try? viewModel.shuffled()
        handler?.startPlaying()
        viewModel.queue.reset()
        playingTrack.send(Track(title: "Shuffled", period: 0.5, fileName: "NO_NAME"))
        playbackPaused.send(false)
    }
    /// Initializes an `Interactor` object with the given `ViewModel`.
    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }
}
