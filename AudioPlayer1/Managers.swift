//
//  DataHandler.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 9/24/18.
//  Copyright © 2018 Hunter Eisler. All rights reserved.
//

import Foundation

// MARK: - TrackManager
class TrackManager {
    var tracks : [Track] {
        didSet {
            try? dataHandler.encodeTracks(tracks)
        }
    }
    var count : Int {
        get {
            return tracks.count
        }
    }
    lazy var dataHandler = DataHandler()
    
    subscript(index : Index) -> Track {
        get {
            if index > tracks.endIndex-1 {
                return tracks[0]
            }
            return tracks[index]
        }
        set {
            tracks[index] = newValue
            try? dataHandler.encodeTracks(tracks)
        }
    }
    // MARK: - Track management
    func append(track: Track) {
        tracks.append(track)
        try? dataHandler.encodeTracks(tracks)
    }
    
    func remove(at index: Index) -> Track {
        defer {
            try? dataHandler.encodeTracks(tracks)
        }
        return tracks.remove(at: index)
    }
    
    // MARK: - Retrieving track info
    func tracks(forIndices indices : [Index]) -> [Track] {
        var someTracks = [Track]()
        for index in indices {
            someTracks.append(tracks[index])
        }
        return someTracks
    }
    
    init(tracks trackArr : [Track]) {
        tracks = trackArr
    }
    
    convenience init() {
        guard let trackArr = try? DataHandler().decodeJSONTracks() else {
            self.init(tracks: DataHandler().defaultTracks())
            return
        }
        self.init(tracks: trackArr)
    }
}


// MARK: - SessionManager
class SessionManager {
    var sessions : [Session] {
        didSet {
            try? dataHandler.encodeSessions(sessions)
        }
    }
    
    var count : Int {
        return sessions.count
    }
    
    lazy var dataHandler = DataHandler()
    
    subscript(index : Index) -> Session {
        return sessions[index]
    }
    
    func tracks(inSession index : Index) -> [Track] {
        return sessions[index].tracks
    }
    
    func add(_ session : Session) {
        sessions.append(session)
    }
    
    /// Removes and returns session if found at index; otherwise, returns nil
    func delete(session index : Index) -> Session? {
        guard sessions.count > index else {
            return nil
        }
        return sessions.remove(at: index)
    }
    
    /// Removes and returns tag if found in session; otherwise, returns nil
    func removeTrack(_ track: Track, fromSession index : Index) -> Track? {
        guard sessions.count > index else {
            return nil
        }
        guard sessions[index].tracks.contains(track) else {
            return nil
        }
        guard let index = sessions[index].tracks.firstIndex(of: track) else {
            return nil
        }
        return sessions[index].tracks.remove(at: index)
        
    }
    
    func addTrack(_ track: Track, toSession index : Index) {
        guard sessions.count > index else { return }
        sessions[index].tracks.append(track)
    }
    
    init(_ sessions : [Session]) {
        self.sessions = sessions
    }
    
    convenience init() {
        guard let sessions = DataHandler().decodeJSONSessions() else {
            self.init([Session]())
            return
        }
        self.init(sessions)
    }
}
