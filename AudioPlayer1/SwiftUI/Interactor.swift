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
        viewModel.tracks.tracks
    }
    var handler: PlaybackHandler?
    let playbackPaused = PassthroughSubject<Bool, Never>()
    let playingTrack = PassthroughSubject<Track, Never>()
    
    func play(track: Track) {
        handler?.stopPlaying()
        viewModel.safeSelectCell(at: tracks.index(of: track))
        handler = try? viewModel.playbackHandler()
        handler?.startPlaying()
        viewModel.queue.reset()
        playingTrack.send(track)
        
    }
    func play(_ index: Int) {
        handler?.stopPlaying()
        viewModel.safeSelectCell(at: index)
        handler = try? viewModel.playbackHandler()
        handler?.startPlaying()
        viewModel.queue.reset()
        playingTrack.send(tracks[index])
    }
    func pauseResume() {
        guard let handler = handler else { return }
        handler.pauseResume()
        playbackPaused.send(!handler.isPlaying)
    }
    
    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }
}
