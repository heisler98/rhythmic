//
//  Handlers.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 9/28/18.
//  Copyright © 2018 Hunter Eisler. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer

// MARK: - PlaybackHandler
///A class for handling track playback.
class PlaybackHandler : NSObject, AVAudioPlayerDelegate {
    ///The handler's queue value.
    var queue : QueueHandler
    ///The handler's track manager.
    var tracks : TrackManager
    ///A Boolean indicating whether the handler is playing a track.
    var isPlaying : Bool = false
    ///A Boolean indicating whether the handler is paused.
    var isPaused : Bool = false
    ///The remote control object.
    unowned let remote = RemoteHandler.shared
    ///The progress delegate receiver.
    weak var progressReceiver : ProgressUpdater?
    
    // MARK: - Playback functions
    ///Begin playing the queued tracks.
    func startPlaying() {
        let player = tracks[queue.now].audioPlayer
        player?.setupRhythm(tracks[queue.now].rhythm)
        player?.delegate = self as AVAudioPlayerDelegate
        player?.progressDelegate = progressReceiver
        isPlaying = player?.play() ?? false
        updateRemote()
    }
    
    ///Stop playing the queued tracks.
    ///This method does not reset the queue.
    func stopPlaying() {
        if isPlaying == true {
            isPlaying = false
            tracks[queue.now].audioPlayer?.stop()
            tracks[queue.now].audioPlayer?.currentTime = 0
        }
    }
    ///Toggle pausing and resuming playback.
    func pauseResume() {
        if isPaused == false {
            tracks[queue.now].audioPlayer?.pause()
            isPaused = true
            return
        } else {
            isPaused = !(tracks[queue.now].audioPlayer!.play())
        }
    }
    ///Skips the currently-playing track.
    func skip() {
        let player = tracks[queue.now].audioPlayer
        player?.stop()
        player?.currentTime = 0.0
        player?.invalidateRhythm()
        
        audioPlayerDidFinishPlaying(player!, successfully: false)
        
    }
    ///Rewinds playback to the beginning; or, if at the beginning, moves to the previous track.
    func rewind() {
        guard let player = tracks[queue.now].audioPlayer else { return }
        if player.currentTime < 5 {
            previous()
        } else {
            player.currentTime = 0.0
            remote.updateInfoCenter(with: tracks[queue.now], audioPlayer: player)
        }
    }
    ///Moves playback to the previous track.
    private func previous() {
        let player = tracks[queue.now].audioPlayer
        player?.stop()
        player?.currentTime = 0.0
        player?.invalidateRhythm()
        
        _ = queue.previous()
        startPlaying()
    }
    
    /**
     Seeks to a `TimeInterval` in the currently-playing track.
     - parameter to: The time interval in seconds.
 */
    func seek(to: TimeInterval) {
        let player = tracks[queue.now].audioPlayer!
        if to < player.duration {
            player.currentTime = to
        }
    }
    /**
     Seeks forward a specific `TimeInterval` in the currently-playing track.
     - parameter interval: The amount of time to seek forward.
 */
    func seekForward(_ interval : TimeInterval) {
        let player = tracks[queue.now].audioPlayer!
        if player.currentTime + interval < player.duration {
            player.currentTime += interval
        } else {
            skip()
        }
    }
    /**
     Seeks backward a specific `TimeInterval` in the currently-playing track.
     - parameter interval: The amount of time to seek backward.
     */
    func seekBackward(_ interval : TimeInterval) {
        let player = tracks[queue.now].audioPlayer!
        if player.currentTime - interval > 0 {
            player.currentTime -= interval
        } else {
            rewind()
        }
    }
    // MARK: - Remote
    ///Update the remote delegate object.
    func updateRemote() {
        remote.updateInfoCenter(with: tracks[queue.now], audioPlayer: tracks[queue.now].audioPlayer!)
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
    }
    // MARK: - Initializers
    /**
     Initialize a `PlaybackHandler` object.
     - throws: Throws a `HandlerError` object if the queue is empty.
     - Parameters:
     
        - queue: A queue of tracks.
        - tracks: A `TrackManager` instance.
 */
    init(queue : Queue, tracks : TrackManager = TrackManager()) throws {
        guard let queued = queue.queued else {
            throw HandlerError.UnexpectedlyFoundNil(Optional<[Index]>.self)
        }
        self.queue = QueueHandler(queued: queued)
        self.tracks = tracks
        super.init()
        remote.handler = self
        //remote.beginReceivingEvents()
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    /**
     Initialize a `PlaybackHandler` object and begin playback.
     - throws: Throws a `HandlerError` object if the queue is empty.
     - Parameters:
     
        - queue: A queue of tracks.
        - start: A Boolean indicating whether to automatically begin playback.
     
     This convenience initializer uses a default instantiation of `TrackManager`.
 */
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

// MARK: - RemoteHandler
///A centralized management type for receiving and interpreting remote audio commands.
class RemoteHandler {
    ///The shared instance of `MPRemoteCommandCenter`.
    let commandCenter = MPRemoteCommandCenter.shared()
    ///The default instance of `MPNowPlayingInfoCenter`.
    let infoCenter = MPNowPlayingInfoCenter.default()
    ///The current `PlaybackHandler`.
    weak var handler : PlaybackHandler?
    ///The shared singleton instance.
    static let shared = RemoteHandler()
    
    ///Updates `MPNowPlayingInfoCenter` with the next track.
    /// - Parameters:
    ///   - track: The currently playing track.
    ///   - audioPlayer: The audio player associated with the track.
    func updateInfoCenter(with track : Track, audioPlayer : AVAudioPlayer) {
        infoCenter.nowPlayingInfo = [
            MPMediaItemPropertyTitle : track.title,
            MPMediaItemPropertyAlbumTitle : "Rhythmic",
            MPNowPlayingInfoPropertyElapsedPlaybackTime : audioPlayer.currentTime,
            MPMediaItemPropertyPlaybackDuration : NSNumber(value: audioPlayer.duration)]
    }
    ///Sets up the remote commands for `MPRemoteCommandCenter`.
    /// - Parameters:
    ///   - handler: The `PlaybackHandler` controlling audio commands.
    private func setupRemoteCommands() {
        /**
        commandCenter.pauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            handler.pauseResume()
            return .success
        }
        commandCenter.playCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            handler.pauseResume()
            return .success
        }
 */
        commandCenter.togglePlayPauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.handler?.pauseResume()
            return .success
        }
        commandCenter.nextTrackCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.handler?.skip()
            return .success
        }
        commandCenter.previousTrackCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.handler?.rewind()
            return .success
        }
        /*
        commandCenter.skipForwardCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            handler.seekForward(15)
            return .success
        }
        commandCenter.skipBackwardCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            handler.seekBackward(15)
            return .success
        }
        commandCenter.seekForwardCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            handler.seekForward(5)
            return .success
        }
        commandCenter.seekBackwardCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            handler.seekBackward(5)
            return .success
        }
        commandCenter.changePlaybackPositionCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            guard let timeEvent = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            handler.seek(to: timeEvent.positionTime)
            return .success
        }
 */
    }
    /**
     Handles a notification that the device's audio route changed.
     - parameter notification: The `Notification` of the route change.
 */
    @objc func audioRouteChanged(_ notification: Notification) {
        guard let userInfo = notification.userInfo, let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt, let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue)  else { return }
        
        switch reason {
        case .newDeviceAvailable:
            let session = AVAudioSession.sharedInstance()
            for output in session.currentRoute.outputs where output.portType == AVAudioSession.Port.headphones {
                guard let handler = self.handler else { return }
                if handler.isPaused { handler.pauseResume() }
            }
            break
        case .oldDeviceUnavailable:
            //pause
            if let previousRoute = userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
                for output in previousRoute.outputs where output.portType == AVAudioSession.Port.headphones {
                    handler?.pauseResume()
                }
            }
            break
        default:()
        }
        
    }
    private init() {
        setupRemoteCommands()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(audioRouteChanged(_:)),
                                               name: AVAudioSession.routeChangeNotification,
                                               object: AVAudioSession.sharedInstance())
    }
}

typealias Index = Int
typealias Position = Int
// MARK: - QueueHandler
///A type to handle a queue of tracks.
struct QueueHandler {
    ///The queued indices of the tracks.
    var queued : [Index]
    ///The current position in the queued indices.
    var position : Position
    ///A computed property of the current queued index.
    var now : Index {
        return queued[position]
    }
    /**
     A subscript getter-setter.
     - parameter position: A position in the queue of indices.
     - returns: The index at the specified position.
 */
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
    /**
     The next index in the queue.
     - returns: The next index.
 */
    mutating func next() -> Index {
        if position < queued.endIndex-1 {
            position += 1
            return queued[position]
        }
        
        position = 0
        return queued[position]
    }
    /**
     The previous index in the queue.
     - returns: The previous index.
 */
    mutating func previous() -> Index {
        if position == queued.startIndex {
            position = queued.endIndex-1
            return queued[position]
        }
        
        position -= 1
        return queued[position]
    }
    ///Resets the position in the queue.
    mutating func reset() {
        position = 0
    }
    
    
    // MARK: - Finding positions
    /**
     Finds and returns the position of an index in the queue.
     - returns: The position of the specified index.
     - parameter of: An index in the queue.
 */
    func position(of: Index) -> Position {
        guard let position = queued.firstIndex(of: of) else { fatalError() }
        return position
    }
    /**
     Finds the position of an index after the specified index.
     - returns: The position after the specified index.
     - parameter after: An index in the queue.
 */
    func position(after : Index) -> Position {
        let before = position(of: after)
        if before < queued.endIndex-1 {
            return before + 1
        }
        return 0
    }
    /**
     Finds the position of an index before the specified index.
     - returns: The position before the specified index.
     - parameter before: An index in the queue.
 */
    func position(before : Index) -> Position {
        let after = position(of: before)
        if after == queued.startIndex {
            return queued.endIndex-1
        }
        return after-1
    }
    /**
     Initializes a `QueueHandler` instance.
     - parameter queue: An array of indices to queue.
 */
    init(queued queue : [Index]) {
        queued = queue
        position = 0
    }
}

// MARK: - DataHandler
///A type to handle data encoding & decoding.
public struct DataHandler {
    ///The `URL` of the documents directory in the user's domain.
    static let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    ///The `URL` of the archive for the JSON track file.
    static let tracksArchiveURL = DataHandler.documentsDirectory.appendingPathComponent("tracks")
    ///The `URL` of the archive for the JSON session file.
    static let sessionsArchiveURL = DataHandler.documentsDirectory.appendingPathComponent("sessions")
    /**
     Decodes the JSON archive of tracks.
     - throws: Throws the `JSONDecoder` error if decoding fails.
     - returns: An array of decoded `Track`s.
 */
    func decodeJSONTracks() throws -> [Track] {
        do {
            let data = try getTracksData()
            return try JSONDecoder().decode([Track].self, from: data)
        } catch {
            print(error)
            throw error
        }
        
    }
    /**
    Decodes the JSON archive of sessions, or returns nil if no sessions are persisted.
     - returns: An optional array of `Session`s.
 */
    func decodeJSONSessions() -> [Session]? {
        do {
            let data = try getSessionsData()
            return try JSONDecoder().decode([Session].self, from: data)
        } catch {
            print(error)
            return nil
        }
    }
    /**
     Persists an array of `Track`s to JSON storage.
     - throws: Throws an error if the array cannot be JSON encoded.
     - parameter tracks: The array of `Tracks` to persist.
 */
    func encodeTracks(_ tracks : [Track]) throws {
        do {
            let data = try JSONEncoder().encode(tracks)
            FileManager.default.createFile(atPath: DataHandler.tracksArchiveURL.path, contents: data, attributes: nil)
        } catch {
            throw error
        }
    }
    /**
     Persists an array of `Session`s to JSON storage.
     - throws: Throws an error if the array cannot be JSON encoded.
     - parameter sessions: The array of `Session`s to persist.
 */
    func encodeSessions(_ sessions : [Session]) throws {
        do {
            let data = try JSONEncoder().encode(sessions)
            FileManager.default.createFile(atPath: DataHandler.sessionsArchiveURL.path, contents: data, attributes: nil)
        } catch {
            throw error
        }
    }
    /**
     Builds and returns a set of tracks from default storage.
     - returns: A preset array of `Track`s.
 */
    func defaultTracks() -> [Track] {
        
        guard let plistUrl = Bundle.main.url(forResource: "Preload", withExtension: "plist") else { fatalError() }
        guard let data = try? Data(contentsOf: plistUrl)  else { fatalError() }
        
        let plistArray = serializePLIST(fromData: data)
        
        return tracks(fromSerialized: plistArray)
    }
    /**
     Removes the asset at the specified URL.
     - parameter url: The URL of the asset to delete.
     - returns: A Boolean value indicating whether the deletion was successful.
 */
    func removeAsset(at url: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: url.path) == true else { return false }
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            print(error)
            return false
        }
        return true
    }
    /**
     Copies the JSON Track object model to an iCloud-backed location.
     - returns: A Boolean value indicating if the backup was successful.
 */
    func backupTracks() -> Bool {
        return backup(DataHandler.tracksArchiveURL)
    }
    /**
     Copies the JSON Track object model to an iCloud-backed location.
     - returns: A Boolean value indicating if the backup was successful.
 */
    func backupSessions() -> Bool {
        return backup(DataHandler.sessionsArchiveURL)
    }
    /**
 */
    func backup() {
        _ = backup(DataHandler.tracksArchiveURL)
        _ = backup(DataHandler.sessionsArchiveURL)
    }
    /**
     Copies an asset to an iCloud-backed location.
     - parameter asset: The asset to backup.
     - returns: A Boolean value indicating success.
 */
    func backup(_ asset: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: asset.path) else { return false }
        let backupURL = DataHandler.documentsDirectory.appendingPathComponent("Inbox", isDirectory: true).appendingPathComponent(asset.lastPathComponent)
        if FileManager.default.fileExists(atPath: backupURL.path) {
            do {
                try FileManager.default.removeItem(at: backupURL)
                try FileManager.default.copyItem(at: asset, to: backupURL)
                return true
            } catch {
                print(error)
                return false
            }
        } else {
            do {
                try FileManager.default.copyItem(at: asset, to: backupURL)
                return true
            } catch {
                print(error)
                return false
            }
        }
    }
    /**
     Copies an asset from one location to another.
     - Parameters:
     
        - bundleURL: The URL of the asset in the bundle.
        - trackURL: The new URL of the asset in the user's domain.
 */
    private func copyAsset(fromBundle bundleURL : URL, toUserDomain trackURL : URL) {
        
        do {
            try FileManager.default.copyItem(at: bundleURL, to: trackURL)
        } catch {
            print(error)
        }
    }
    /**
     Sets the preferred URLFileProtection resource value on the specified URL.
     - parameter on: The item's URL to set the value on.
     - returns: A Boolean value indicating success.
 */
    static func setPreferredFileProtection(on: URL) -> Bool {
        let url = on as NSURL
        let key = URLResourceKey.fileProtectionKey
        let value = URLFileProtection.completeUntilFirstUserAuthentication
        do {
            try url.setResourceValue(value, forKey: key)
            return true
        } catch {
            print(error)
            return false
        }
    }
    /**
     Builds and returns a set of tracks from property-list configuration.
     - returns: An array of `Track`s.
     - parameter serial: An array of dictionaried representations of a property list.
 */
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
    /**
     Serializes a dictionaried representation of a property list from data.
     - returns: An array of dictionaried representations of a property list.
     - parameter data: Property list data.
 */
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
    /**
     Retrieves the data at the tracks archive URL.
     - throws: Throws a `HandlerError` if no data can be found.
     - returns: The data of the JSON archive.
 */
    private func getTracksData() throws -> Data {
        guard let data = FileManager.default.contents(atPath: DataHandler.tracksArchiveURL.path) else {
            throw HandlerError.NoDataFound(DataHandler.tracksArchiveURL.path)
        }
        return data
    }
    /**
     Retrieves the data at the sessions archive URL.
     - throws: Throws a `HandlerError` if no data can be found.
     - returns: The data of the JSON archive.
     */
    private func getSessionsData() throws -> Data {
        guard let data = FileManager.default.contents(atPath: DataHandler.sessionsArchiveURL.path) else {
            throw HandlerError.NoDataFound(DataHandler.sessionsArchiveURL.path)
        }
        return data
    }
}
///The protocol for subscript access of UserDefault preferences.
protocol Preferences {
    /**
     A subscript getter-setter for preferences.
     - returns: A `Float`, or nil if no value exists for the key.
     - parameter key: The preference key.
 */
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
///The wrapper type for user preferences.
struct PrefsHandler {
    ///The preference storage mechanism conforming to `Preferences`.
    var prefs : Preferences
    /**
     Initializes a `PrefsHandler` object.
     - parameter prefs: A preference mechanism conforming to `Preferences`. The standard `UserDefaults` instantiation is used by default.
 */
    init(prefs : Preferences = UserDefaults.standard) {
        self.prefs = prefs
    }
}
