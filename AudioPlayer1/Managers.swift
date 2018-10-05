//
//  DataHandler.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 9/24/18.
//  Copyright © 2018 Hunter Eisler. All rights reserved.
//

import Foundation

// MARK: - TrackManager
///The manager of all `Track` instances.
class TrackManager {
    ///The master collection of `Track`s.
    var tracks : [Track] {
        didSet {
            try? dataHandler.encodeTracks(tracks)
        }
    }
    ///The number of `Track`s accessible to the manager.
    var count : Int {
        get {
            return tracks.count
        }
    }
    ///The persistent storage mechanism.
    lazy var dataHandler = DataHandler()
    /**
     A subscript getter-setter.
     - returns: A `Track` at the specified index.
     - parameter index: An index of a `Track`.
 */
    subscript(index : Index) -> Track {
        get {
            if index > tracks.endIndex-1 {
                return tracks[0]
            }
            return tracks[index]
        }
        set {
            tracks[index] = newValue
        }
    }
    // MARK: - Track management
    /**
     Appends a `Track` to the master collection.
     - parameter track: The `Track` to append.
 */
    func append(track: Track) {
        tracks.append(track)
    }
    /**
     Removes a `Track` from the master collection.
     - parameter index: The index of the `Track` to remove.
     - returns: The removed `Track` object.
     */
    func remove(at index: Index) -> Track {
        return tracks.remove(at: index)
    }
    
    // MARK: - Retrieving track info
    /**
     Finds all the `Track`s at the collection of indices.
     - parameter indices: A collection of `Track` indices.
     - returns: A collection of `Track`s from the specified indices.
     */
    func tracks(forIndices indices : [Index]) -> [Track] {
        var someTracks = [Track]()
        for index in indices {
            someTracks.append(tracks[index])
        }
        return someTracks
    }
    /**
     Initializes a `TrackManager` object.
     - parameter trackArr: A collection of `Track`s.
     */
    init(tracks trackArr : [Track]) {
        tracks = trackArr
    }
    /**
     Initializes a `TrackManager` object with the tracks located at the archive, or the default preset tracks from the bundle.
     */
    convenience init() {
        guard let trackArr = try? DataHandler().decodeJSONTracks() else {
            self.init(tracks: DataHandler().defaultTracks())
            return
        }
        self.init(tracks: trackArr)
    }
}


// MARK: - SessionManager
///A manager for sessions.
class SessionManager {
    ///The master collection of sessions.
    var sessions : [Session] {
        didSet {
            try? dataHandler.encodeSessions(sessions)
        }
    }
    ///The amount of sessions accessible to the manager.
    var count : Int {
        return sessions.count
    }
    ///The persistent storage mechanism for the manager.
    lazy var dataHandler = DataHandler()
    /**
     A subscript getter for accessing a `Session`.
     - parameter index: An index of a `Session`.
     - returns: The `Session` at the index.
 */
    subscript(index : Index) -> Session {
        return sessions[index]
    }
    /**
     Returns the `Track`s in a `Session`.
     - parameter index: An index of a `Session`.
     - returns: A collection of `Track`s in the specified `Session`.
     */
    func tracks(inSession index : Index) -> [Track] {
        return sessions[index].tracks
    }
    /**
     Add a `Session` to the master collection.
     - parameter session: The `Session` to append.
     */
    func add(_ session : Session) {
        sessions.append(session)
    }
    /**
     Removes a `Session` from the master collection.
     - parameter index: The index of the `Session`.
     - returns: The `Session` object removed, or nil if no session exists at that index.
     */
    func delete(session index : Index) -> Session? {
        guard sessions.count > index else {
            return nil
        }
        return sessions.remove(at: index)
    }
    
    /**
     Removes a `Track` from a specified `Session`.
     - returns: The `Track` object removed, or nil.
     - Parameters:
    
        - track: The `Track` to remove.
        - index: The index of a `Session` from which to remove the track.
 */
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
    /**
     Adds a `Track` to a specified `Session`.
     - Parameters:
    
        - track: A `Track` to add to a `Session`.
        - index: An index of a `Session`.
     */
    func addTrack(_ track: Track, toSession index : Index) {
        guard sessions.count > index else { return }
        sessions[index].tracks.append(track)
    }
    /**
     Initializes a `SessionManager` object.
     - parameter sessions: A collection of `Session`s to manage.
     */
    init(_ sessions : [Session]) {
        self.sessions = sessions
    }
    /**
     Initializes a `SessionManager` object using sessions from persistent storage, or an empty set of `Session`s.
     */
    convenience init() {
        guard let sessions = DataHandler().decodeJSONSessions() else {
            self.init([Session]())
            return
        }
        self.init(sessions)
    }
}
