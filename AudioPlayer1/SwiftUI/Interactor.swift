//
//  Interactor.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 8/13/20.
//  Copyright © 2020 Hunter Eisler. All rights reserved.
//

import Combine

class Interactor: ObservableObject {
    var viewModel: ViewModel
    var tracks: [Track] {
        viewModel.sorter.resort(by: .DateAddedAscending)
        return viewModel.sorter.sorted.map { $1 }
    }
    var handler: PlaybackHandler?
    let playbackPaused = PassthroughSubject<Bool, Never>()
    let playingTrack = PassthroughSubject<Track, Never>()
    
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
    func play(_ index: Int) {
        handler?.stopPlaying()
        viewModel.safeSelectCell(at: index)
        handler = try? viewModel.playbackHandler()
        handler?.startPlaying()
        viewModel.queue.reset()
        playingTrack.send(tracks[index])
        playbackPaused.send(false)
    }
    func pauseResume() {
        guard let handler = handler else { return }
        handler.pauseResume()
        playbackPaused.send(!handler.isPlaying)
    }
    
    func skip() {
        handler?.skip()
        playbackPaused.send(false)
    }
    
    func rewind() {
        handler?.rewind()
        playbackPaused.send(false)
    }
    
    func playAll() {
        handler?.stopPlaying()
        handler = try? viewModel.playAll()
        handler?.startPlaying()
        viewModel.queue.reset()
        playingTrack.send(Track(title: "All Tracks", period: 0.5, fileName: "NO_NAME"))
        playbackPaused.send(false)
    }
    
    func shuffle() {
        handler?.stopPlaying()
        handler = try? viewModel.shuffled()
        handler?.startPlaying()
        viewModel.queue.reset()
        playingTrack.send(Track(title: "Shuffled", period: 0.5, fileName: "NO_NAME"))
        playbackPaused.send(false)
    }
    
    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }
}
