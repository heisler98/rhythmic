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
    let remote = RemoteHandler.shared
    ///The progress delegate receiver.
    weak var progressReceiver : ProgressUpdater?
    ///The current pan audio player.
    var player: PanAudioPlayer?
    
    // MARK: - Playback functions
    ///Begin playing the queued tracks.
    func startPlaying() {
        player = tracks[queue.now].panAudioPlayer()
        player?.setupRhythm(tracks[queue.now].rhythm)
        player?.delegate = self as AVAudioPlayerDelegate
        player?.progressDelegate = progressReceiver
        isPlaying = player?.play() ?? false
        updateRemote()
    }
    /**
     Begin playback at a specific position in the playlist.
     - parameter position: The position where playback should begin.
     If the position is outside the bounds of the playlist, playback will not begin.
 */
    func play(at position: Position) {
        guard position < queue.queued.endIndex else { return }
        queue.position = position
        startPlaying()
    }
    
    ///Stop playing the queued tracks.
    ///This method does not reset the queue.
    func stopPlaying() {
        if isPlaying == true {
            isPlaying = false
            player?.stop()
            player?.currentTime = 0
        }
    }
    ///Toggle pausing and resuming playback.
    func pauseResume() {
        if isPaused == false {
            pause()
            return
        } else {
            resume()
        }
    }
    ///Pauses playback.
    func pause() {
        guard isPaused == false else { return }
        guard let player = player else { return }
        player.pause()
        isPaused = true
        remote.updatePlaybackInfo(to: player.currentTime, rate: 0.0)
    }
    ///Resumes playback.
    func resume() {
        guard isPaused == true else { return }
        guard let player = player else { return }
        isPaused = !(player.play())
        remote.updatePlaybackInfo(to: player.currentTime, rate: 1.0)
    }
    ///Skips the currently-playing track.
    func skip() {
        guard let _ = player else {
            queue.next()
            startPlaying()
            return
        }
        player!.stop()
        player!.currentTime = 0.0
        player!.invalidateRhythm()
        
        audioPlayerDidFinishPlaying(player!, successfully: false)
        
    }
    ///Rewinds playback to the beginning; or, if at the beginning, moves to the previous track.
    func rewind() {
        guard let _ = player else {
            queue.previous()
            startPlaying()
            return
        }
        if player!.currentTime < 5 {
            previous()
        } else {
            player!.currentTime = 0.0
            remote.updateInfoCenter(with: tracks[queue.now], audioPlayer: player!)
        }
    }
    ///Moves playback to the previous track.
    private func previous() {
        player?.stop()
        player?.currentTime = 0.0
        player?.invalidateRhythm()
        
        queue.previous()
        startPlaying()
    }
    
    /**
     Seeks to a `TimeInterval` in the currently-playing track.
     - parameter to: The time interval in seconds.
 */
    func seek(to: TimeInterval) {
        player?.currentTime = to
        remote.updatePlaybackInfo(to: to, rate: 1.0)
    }
    /**
     Seeks forward a specific `TimeInterval` in the currently-playing track.
     - parameter interval: The amount of time to seek forward.
 */
    func seekForward(_ interval : TimeInterval) {
        guard let _ = player else { return }
        if player!.currentTime + interval < player!.duration {
            player!.currentTime += interval
        } else {
            skip()
        }
    }
    /**
     Seeks backward a specific `TimeInterval` in the currently-playing track.
     - parameter interval: The amount of time to seek backward.
     */
    func seekBackward(_ interval : TimeInterval) {
        guard let _ = player else { return }
        if player!.currentTime - interval > 0 {
            player!.currentTime -= interval
        } else {
            rewind()
        }
    }
    // MARK: - Remote
    ///Update the remote delegate object.
    func updateRemote() {
        guard let _ = player else { return }
        remote.updateInfoCenter(with: tracks[queue.now], audioPlayer: player!)
    }
    
    // MARK: - AVAudioPlayerDelegate methods
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        dLog(error as Any)
        isPlaying = false
        let corruptPosition = queue.position
        queue.queued.remove(at: corruptPosition)
        queue.next()
        startPlaying()
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.player?.invalidateRhythm()
        queue.next()
        startPlaying()
    }
    // MARK: - Initializers
    /**
     Initialize a `PlaybackHandler` object.
     - throws: Throws a `HandlerError` if the queue is empty.
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
            MPMediaItemPropertyPlaybackDuration : NSNumber(value: audioPlayer.duration),
            MPNowPlayingInfoPropertyPlaybackRate : NSNumber(value: 1.0)]
    }
    /**
     Updates the info center's playback time and rate.
     - Parameters:
     
        - playbackTime: The player's new playback time.
        - rate: The player's playback rate. (`0.0` for paused, `1.0` for playing).
 */
    func updatePlaybackInfo(to playbackTime: TimeInterval, rate: Float) {
        infoCenter.nowPlayingInfo![MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: playbackTime)
        infoCenter.nowPlayingInfo![MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(value: rate)
    }
    
    ///Sets up the remote commands for `MPRemoteCommandCenter`.
    /// - Parameters:
    ///   - handler: The `PlaybackHandler` controlling audio commands.
    private func setupRemoteCommands() {
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
        commandCenter.changePlaybackPositionCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            guard let timeEvent = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self.handler?.seek(to: timeEvent.positionTime)
            return .success
        }

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
            for output in session.currentRoute.outputs where (output.portType == AVAudioSession.Port.headphones || output.portType == AVAudioSession.Port.carAudio) {
                guard let handler = self.handler else { return }
                handler.resume()
            }
            break
        case .oldDeviceUnavailable:
            //pause
            if let previousRoute = userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
                for output in previousRoute.outputs where (output.portType == AVAudioSession.Port.headphones || output.portType == AVAudioSession.Port.carAudio) {
                    guard let handler = self.handler else { return }
                    handler.pause()
                }
            }
            break
        default:()
        }
        
    }
    
    @objc func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
        }
        if type == .began {
            handler?.pause()
        } else if type == .ended {
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    guard let handler = handler else { return }
                    handler.resume()
                } else {
                    
                }
            }
        }
        if userInfo.contains(where: { (arg0) -> Bool in
            let (key, _) = arg0
            if let keyString = key as? String {
                return keyString == AVAudioSessionInterruptionWasSuspendedKey
            }
            return false
        }) {
            dLog("Interruption was a suspension by system.")
        }
    }
    
    private init() {
        setupRemoteCommands()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(audioRouteChanged(_:)),
                                               name: AVAudioSession.routeChangeNotification,
                                               object: AVAudioSession.sharedInstance())
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleInterruption(_:)),
                                               name: AVAudioSession.interruptionNotification,
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
    @discardableResult
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
    @discardableResult
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
// MARK: - SortHandler
///A type to handle table sort functionality.
class SortHandler {
    private var tracks: EnumeratedSequence<[Track]>
    private static let key = "kRhythmicDefaultDescriptor"
    enum Descriptor : Int {
        case Lexicographic = 0
        case DateAddedDescending
        case Tempo
        case DateAddedAscending
    }
    var sorted: [(offset: Int, element: Track)]
    var by: Descriptor = .DateAddedDescending {
        didSet {
            resort(by: by)
        }
    }
    
    func resort(by option: Descriptor = .DateAddedDescending) {
        switch option {
        case .Lexicographic:
            lexicographicSort()
            break
        case .DateAddedDescending:
            descendingDateAddedSort()
            break
        case .Tempo:
            tempoSort()
            break
        case .DateAddedAscending:
            ascendingDateAddedSort()
            break
        }
        SortHandler.updateDefaults(to: option)
    }
    
    func updateEnumerated(_ enumerated: EnumeratedSequence<[Track]>) {
        self.tracks = enumerated
        resort(by: self.by)
    }
    
    private func lexicographicSort() {
        sorted = tracks.sorted(by: { (first, second) -> Bool in
            return first.element.title.lowercased() < second.element.title.lowercased()
        })
    }
    
    private func descendingDateAddedSort() {
        sorted = tracks.sorted(by: { (first, second) -> Bool in
            return first.offset < second.offset
        })
    }
    
    private func tempoSort() {
        sorted = tracks.sorted(by: { (first, second) -> Bool in
            return first.element.period < second.element.period
        })
    }
    
    private func ascendingDateAddedSort() {
        sorted = tracks.reversed()
    }
    
    func masterIndex(for index: Index) -> Index {
        switch by {
        case .DateAddedDescending:
            return index
        default:
            return sorted[index].offset
        }
    }
    
    func index(of element: Track) -> Index? {
        switch by {
        case .DateAddedDescending:
            for tuple in tracks where tuple.element == element {
                return tuple.offset
            }
            break
        default:
            for tuple in sorted where tuple.element == element {
                return sorted.firstIndex(where: { (inner) -> Bool in
                    inner == tuple
                })
            }
            break
        }
        return nil
    }
    
    static func updateDefaults(to descriptor: Descriptor) {
        UserDefaults.standard.set(descriptor.rawValue, forKey: key)
    }
    static func defaultDescriptor() -> Descriptor? {
        let intValue = UserDefaults.standard.integer(forKey: key)
        return Descriptor(rawValue: intValue)
    }
    
    init(enumerated: EnumeratedSequence<[Track]>) {
        self.tracks = enumerated
        self.sorted = enumerated.sorted { _,_ in return true }
        self.by = SortHandler.defaultDescriptor() ?? .DateAddedDescending
        resort(by: SortHandler.defaultDescriptor() ?? .DateAddedDescending)
        
    }
}

// MARK: - DataHandler
///A type to handle data encoding & decoding.
public struct DataHandler {
    ///The `URL` of the documents directory in the user's domain.
    static let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    ///The `URL` of the archive for the JSON track file.
    static let tracksArchiveURL = DataHandler.documentsDirectory.appendingPathComponent("files/tracks")
    ///The `URL` of the archive for the JSON session file.
    static let sessionsArchiveURL = DataHandler.documentsDirectory.appendingPathComponent("files/sessions")
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
            dLog(error)
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
            dLog(error)
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
    @discardableResult
    func removeAsset(at url: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: url.path) == true else { return false }
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            dLog(error)
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
                dLog(error)
                return false
            }
        } else {
            do {
                try FileManager.default.copyItem(at: asset, to: backupURL)
                return true
            } catch {
                dLog(error)
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
    func copyAsset(fromBundle bundleURL : URL, toUserDomain trackURL : URL) {
        
        do {
            try FileManager.default.copyItem(at: bundleURL, to: trackURL)
        } catch {
            dLog(error)
        }
    }
    /**
     Sets the preferred URLFileProtection resource value on the specified URL.
     - parameter on: The item's URL to set the value on.
     - returns: A Boolean value indicating success.
 */
    static func setPreferredFileProtection(on: URL) -> Bool {
        do {
            try FileManager.default.setAttributes([.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication], ofItemAtPath: on.path)
            return true
        } catch {
            dLog(error)
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
            dLog(error)
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

final class TempoHandler {
    public static let core = TempoHandler()
    public func tempo(of url: URL, completion: ((Double?) ->())?) -> Double? {
        let tempo = Double(Superpowered().offlineAnalyze(url))
        if tempo > 0 {
            completion?(tempo)
            return tempo
        } else {
            completion?(nil)
            return nil
        }
    }
}
