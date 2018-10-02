//
//  Handlers.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 9/28/18.
//  Copyright © 2018 Hunter Eisler. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import MediaPlayer

// MARK: - PlaybackHandler
class PlaybackHandler : NSObject, AVAudioPlayerDelegate {
    var queue : QueueHandler
    var tracks : TrackManager
    var isPlaying : Bool = false
    
    // MARK: - Playback functions
    func startPlaying() {
        guard let player = tracks[queue.now].audioPlayer else { fatalError() }
        player.setupRhythm(tracks[queue.now].rhythm)
        player.delegate = self as AVAudioPlayerDelegate
        isPlaying = player.play()
        beginReceivingEvents()
    }
    
    func stopPlaying() {
        if isPlaying == true {
            isPlaying = false
            tracks[queue.now].audioPlayer?.stop()
        }
    }
    
    func pauseResume() {
        if isPlaying == true {
            tracks[queue.now].audioPlayer?.pause()
            isPlaying = false
            return
        } else {
            isPlaying = tracks[queue.now].audioPlayer?.play() ?? false
        }
    }
    
    func skip() {
        let player = tracks[queue.now].audioPlayer
        player?.stop()
        player?.currentTime = 0.0
        player?.invalidateRhythm()
        
        audioPlayerDidFinishPlaying(player!, successfully: false)
        
    }
    
    func previous() {
        let player = tracks[queue.now].audioPlayer
        player?.stop()
        player?.currentTime = 0.0
        player?.invalidateRhythm()
        
        _ = queue.previous()
        startPlaying()
    }
    
    func seek(to: TimeInterval) {
        let player = tracks[queue.now].audioPlayer!
        if to < player.duration {
            player.currentTime = to
        }
    }
    
    func seekForward(_ interval : TimeInterval) {
        let player = tracks[queue.now].audioPlayer!
        if player.currentTime + interval < player.duration {
            player.currentTime += interval
        } else {
            skip()
        }
    }
    
    func seekBackward(_ interval : TimeInterval) {
        let player = tracks[queue.now].audioPlayer!
        if player.currentTime - interval > 0 {
            player.currentTime -= interval
        } else {
            previous()
        }
    }
    // MARK: - MPRemoteCommandCenter
    func beginReceivingEvents() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        updateNowPlayingCenter()
        setupRemoteCommands()
    }
    
    func updateNowPlayingCenter() {
        var track = tracks[queue.now]
        let center = MPNowPlayingInfoCenter.default()
        center.nowPlayingInfo = [MPMediaItemPropertyTitle : track.title, MPMediaItemPropertyAlbumTitle : "Rhythmic", MPNowPlayingInfoPropertyElapsedPlaybackTime : track.audioPlayer!.currentTime, MPMediaItemPropertyPlaybackDuration : NSNumber(value: track.audioPlayer!.duration)]
    }
    
    func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.pauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.pauseResume()
            return .success
        }
        center.playCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.pauseResume()
            return .success
        }
        center.nextTrackCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.skip()
            return .success
        }
        center.previousTrackCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.previous()
            return .success
        }
        center.skipForwardCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            guard let command = event.command as? MPSkipIntervalCommand else { return .commandFailed }
            self.seekForward(command.preferredIntervals[0].doubleValue)
            return .success
        }
        center.skipBackwardCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            guard let command = event.command as? MPSkipIntervalCommand else { return .commandFailed }
            self.seekBackward(command.preferredIntervals[0].doubleValue)
            return .success
        }
        center.seekForwardCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.seekForward(5)
            return .success
        }
        center.seekBackwardCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.seekBackward(5)
            return .success
        }
        center.changePlaybackPositionCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            guard let timeEvent = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self.seek(to: timeEvent.positionTime)
            return .success
        }
    }
    
    // MARK: - AVAudioPlayerDelegate methods
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        isPlaying = false
        let corruptPosition = queue.position
        queue.queued.remove(at: corruptPosition)
        _ = queue.next()
        startPlaying()
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        tracks[queue.now].audioPlayer?.invalidateRhythm()
        
        _ = queue.next()
        startPlaying()
        updateNowPlayingCenter()
    }
    // MARK: - Initializers
    init(queue : Queue, tracks : TrackManager) throws {
        guard let queued = queue.queued else {
            throw HandlerError.UnexpectedlyFoundNil(Optional<[Index]>.self)
        }
        
        self.queue = QueueHandler(queued: queued)
        self.tracks = tracks
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    convenience init(queue: Queue, start : Bool = true) throws {
        do {
            try self.init(queue: queue, tracks : TrackManager())
        } catch {
            throw error
        }
        if start == true {
            startPlaying()
        }
    }
}


typealias Index = Int
typealias Position = Int
// MARK: - QueueHandler
struct QueueHandler {
    var queued : [Index]
    var position : Position
    var now : Index {
        return queued[position]
    }
    
    subscript(position : Position) -> Index {
        get {
            if position > queued.endIndex-1 {
                return queued[0]
            }
            return queued[position]
        }
        set {
            queued[position] = newValue
        }
    }
    
    // MARK: - Queue management
    mutating func next() -> Index {
        if position < queued.endIndex-1 {
            position += 1
            return queued[position]
        }
        
        position = 0
        return queued[position]
    }
    
    mutating func previous() -> Index {
        if position == queued.startIndex {
            position = queued.endIndex-1
            return queued[position]
        }
        
        position -= 1
        return queued[position]
    }
    
    mutating func reset() {
        position = 0
    }
    
    
    // MARK: - Finding positions
    func position(of: Index) -> Position {
        guard let position = queued.firstIndex(of: of) else { fatalError() }
        return position
    }
    
    func position(after : Index) -> Position {
        let before = position(of: after)
        if before < queued.endIndex-1 {
            return before + 1
        }
        return 0
    }
    
    func position(before : Index) -> Position {
        let after = position(of: before)
        if after == queued.startIndex {
            return queued.endIndex-1
        }
        return after-1
    }
    
    init(queued queue : [Index]) {
        queued = queue
        position = 0
    }
}


public struct DataHandler {
    
    static let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    static let tracksArchiveURL = DataHandler.documentsDirectory.appendingPathComponent("tracks")
    static let sessionsArchiveURL = DataHandler.documentsDirectory.appendingPathComponent("sessions")
    
    func decodeJSONTracks() throws -> [Track] {
        do {
            let data = try getTracksData()
            return try JSONDecoder().decode([Track].self, from: data)
        } catch {
            print(error)
            throw error
        }
        
    }
    /// Decodes persisted sessions, or returns nil if none are encoded.
    func decodeJSONSessions() -> [Session]? {
        do {
            let data = try getSessionsData()
            return try JSONDecoder().decode([Session].self, from: data)
        } catch {
            print(error)
            return nil
        }
    }
    
    func encodeTracks(_ tracks : [Track]) throws {
        do {
            let data = try JSONEncoder().encode(tracks)
            FileManager.default.createFile(atPath: DataHandler.tracksArchiveURL.path, contents: data, attributes: nil)
        } catch {
            throw error
        }
    }
    
    func encodeSessions(_ sessions : [Session]) throws {
        do {
            let data = try JSONEncoder().encode(sessions)
            FileManager.default.createFile(atPath: DataHandler.sessionsArchiveURL.path, contents: data, attributes: nil)
        } catch {
            throw error
        }
    }
    
    func defaultTracks() -> [Track] {
        
        guard let plistUrl = Bundle.main.url(forResource: "Tracks", withExtension: "plist") else { fatalError() }
        guard let data = try? Data(contentsOf: plistUrl)  else { fatalError() }
        
        let plistArray = serializePLIST(fromData: data)
        
        return tracks(fromSerialized: plistArray)
    }
    
    private func copyAsset(fromBundle bundleURL : URL, toUserDomain trackURL : URL) {
        
        do {
            try FileManager.default.copyItem(at: bundleURL, to: trackURL)
        } catch {
            print(error)
        }
    }
    
    private func tracks(fromSerialized serial: [Dictionary<String, String>]) -> [Track] {
        var tracks = [Track]()
        
        for aDict in serial {
            let file = aDict["title"]! + "." + aDict["extension"]!
            let track = Track(title: aDict["title"]!, period: Double(aDict["period"]!)!, fileName: file)
            tracks.append(track)
            
            let bundleURL = Bundle.main.url(forResource: aDict["title"]!, withExtension: aDict["extension"]!)
            copyAsset(fromBundle: bundleURL!, toUserDomain: track.url)
        }
        return tracks
    }
    
    private func serializePLIST(fromData data : Data) -> [Dictionary<String, String>] {
        var tracks : [Dictionary<String, String>]?
        
        do {
            tracks = try PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil) as? [Dictionary<String, String>]
        } catch {
            print(error)
        }
        guard tracks != nil else { fatalError() }
        return tracks!
    }
    
    private func getTracksData() throws -> Data {
        guard let data = FileManager.default.contents(atPath: DataHandler.tracksArchiveURL.path) else {
            throw HandlerError.NoDataFound(DataHandler.tracksArchiveURL.path)
        }
        return data
    }
    
    private func getSessionsData() throws -> Data {
        guard let data = FileManager.default.contents(atPath: DataHandler.sessionsArchiveURL.path) else {
            throw HandlerError.NoDataFound(DataHandler.tracksArchiveURL.path)
        }
        return data
    }
}

protocol Preferences {
    subscript(key : String) -> Float? { get set }
}

extension UserDefaults : Preferences {
    subscript(key: String) -> Float? {
        get {
            return self.object(forKey: key) as? Float
        }
        set {
            self.set(newValue, forKey: key)
        }
    }
}
// testable
struct PrefsHandler {
    var prefs : Preferences
    
    init(prefs : Preferences = UserDefaults.standard) {
        self.prefs = prefs
    }
}
