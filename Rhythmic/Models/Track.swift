//
//  Track.swift
//  Rhythmic
//
//  Created by Hunter Eisler on 8/11/20.
//

import Foundation

/// A type representing a playable track.
struct Track: Codable {
    /// The human-readable title of the track.
    let title: String
    /// The period of the track.
    /// - note: 60 divided by BPM.
    let period: Float
    /// The file path to the track. 
    let path: String
}
