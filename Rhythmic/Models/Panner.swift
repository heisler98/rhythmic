//
//  Panner.swift
//  Rhythmic
//
//  Created by Hunter Eisler on 8/11/20.
//

import Foundation
import FileKit
import os

/// An object responsible for panning an audio player.
open class Panner {
    
    private var player: Pannable?
    private var timer: Timer?
    
    /// Starts panning an audio player at the specified interval.
    /// - parameters:
    ///     - next: The player to pan.
    ///     - period: The timer interval.
    func start(_ next: Pannable, _ period: Float) {
        invalidate()
        
        player = next
        player?.pan = 0.87
        
        timer = Timer(timeInterval: Double(period), repeats: true, block: { [weak self] _ in
            self?.player?.pan *= -1
        })
        RunLoop.current.add(timer!, forMode: .common)
        timer?.fire()
    }
    
    private func invalidate() {
        timer?.invalidate()
    }
    
    deinit {
        invalidate()
    }
}

protocol Pannable {
    var pan: Float { get set }
}
