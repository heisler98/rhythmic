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
            persist()
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
    ///An enumerated sequence of the master collection.
    var enumerated : EnumeratedSequence<[Track]> {
        return self.tracks.enumerated()
    }
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
        _ = dataHandler.removeAsset(at: tracks[index].url)
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
 */
    fileprivate func persist() {
        try? dataHandler.encodeTracks(tracks)
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
            persist()
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
        guard let tIndex = sessions[index].tracks.firstIndex(of: track) else {
            return nil
        }
        return sessions[index].tracks.remove(at: tIndex)
        
    }
    /**
     Removes a Track at a specified index from a specified Session.
     - returns: The track removed, or nil if no track exists at that index.
     - parameters:
     
        - trackIndex: The index of a Track in a Session.
        - sessionIndex: The index of a Session.
 */
    func removeTrack(at trackIndex: Index, fromSession sessionIndex: Index) -> Track? {
        guard sessions.indices.contains(sessionIndex) == true else { return nil }
        guard sessions[sessionIndex].tracks.indices.contains(trackIndex) == true else { return nil }
        return sessions[sessionIndex].tracks.remove(at: trackIndex)
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
     Removes every equivalent track from all sessions.
     - parameter track: The `Track` to remove.
     
     This method will remove every equivalent `Track` object from any session which contains one. Call this method when a `Track` is deleted from the store, or is otherwise unaccessible.
 */
    func deleteEvery(_ track: Track) {
        for session in sessions where session.tracks.contains(track) {
            let index = sessions.index(of: session)
            sessions[index].tracks.removeAll { (inside) -> Bool in
                return inside == track
            }
        }
    }
    
    ///Persists the current model to the store.
    func persist() {
        try? dataHandler.encodeSessions(sessions)
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

extension SessionManager : SessionResponder {
    func rhythmChanged(_ to: Rhythmic, at trackIndex: Index, in sessionIndex: Index) {
        guard sessions.indices.contains(sessionIndex) else { return }
        guard sessions[sessionIndex].tracks.indices.contains(trackIndex) else { return }
        sessions[sessionIndex].tracks[trackIndex].rhythm = to
    }
    
    func rateChanged(_ to: PanRate, at trackIndex: Index, in sessionIndex: Index) {
        guard sessions.indices.contains(sessionIndex) else { return }
        guard sessions[sessionIndex].tracks.indices.contains(trackIndex) else { return }
        sessions[sessionIndex].tracks[trackIndex].rate = to
    }
    
    func trackRemoved(at index: Index, from sessionIndex: Index) {
        _ = removeTrack(at: index, fromSession: sessionIndex)
    }
    
    func trackMoved(from oldIndex: Index, to newIndex: Index, in sessionIndex: Index) {
        guard sessions.indices.contains(sessionIndex) else { return }
        sessions[sessionIndex].tracks.moveElement(at: oldIndex, to: newIndex)
    }
    
    func addedTrack(_ track: Track, to sessionIndex: Index) {
        guard sessions.indices.contains(sessionIndex) else { return }
        addTrack(track, toSession: sessionIndex)
    }
    
    func changedAll(to rhythm: Rhythmic, in sessionIndex: Index) {
        guard sessions.indices.contains(sessionIndex) else { return }
        for index in sessions[sessionIndex].tracks.indices {
            sessions[sessionIndex].tracks[index].rhythm = rhythm
        }
    }
}

class SessionTrackManager : TrackManager {
    override func persist() { }
}

extension Array where Element: Equatable {
    /**
     Moves an element at a specified index to a new index.
     - parameters:
     
        - at: The index of an element.
        - to: The new index of the element.
 */
    mutating func moveElement(at: Index, to: Index) {
        guard at != to && indices.contains(at) && indices.contains(to) else { return }
        insert(remove(at: at), at: to)
    }
    
    /**
     Returns the index of the given element.
     - parameter of: An element in the collection.
     - returns: The index of the given element.
     
     The first index where the given element is found in the collection will be returned. If the element cannot be found in the collection, this function returns `NSNotFound`.
 */
    func index(of: Element) -> Index {
        let firstIndex = self.firstIndex(of: of)
        return firstIndex ?? NSNotFound
    }
}

///A protocol to conform to track editing in a Session.
protocol SessionResponder: AnyObject {
    /**
     Indicates a Track was removed from a specified Session.
     - parameters:
     
        - index: The index of a Track.
        - sessionIndex: The index of the Session.
     */
    func trackRemoved(at index: Index, from sessionIndex: Index)
    /**
     Indicates a Track was moved from one position to another inside a Session.
     - parameters:
     
        - oldIndex: The former index of the Track.
        - newIndex: The new index of the Track.
        - sessionIndex: The index of the Session.
     */
    func trackMoved(from oldIndex: Index, to newIndex: Index, in sessionIndex: Index)
    /**
     Indicates a Track was added to a Session.
     - parameters:
     
        - track: The Track to append.
        - sessionIndex: The index of the Session.
     */
    func addedTrack(_ track: Track, to sessionIndex: Index)
    /**
     Indicates the rhythm of a Track was changed.
     - parameters:
     
        - to: The new rhythm.
        - trackIndex: The index of the Track in the Session.
        - sessionIndex: The index of the Session.
     */
    func rhythmChanged(_ to: Rhythmic, at trackIndex: Index, in sessionIndex: Index)
    /**
     Indicates the rate of a Track was changed.
     - parameters:
     
        - to: The new rate.
        - trackIndex: The index of the Track in the Session.
        - sessionIndex: The index of the Session.
     */
    func rateChanged(_ to: PanRate, at trackIndex: Index, in sessionIndex: Index)
    
}
