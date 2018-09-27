//
//  PanAudioPlayer.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 7/14/17.
//  Copyright © 2017 Hunter Eisler. All rights reserved.
//  Unauthorized copying of this file via any medium is strictly prohibited.
//  *Proprietary and confidential*

import UIKit
import AVFoundation
import MediaPlayer
import os.log

// MARK: - Global definitions

typealias TrackArray = Array<Track>
let pi = 3.14159265
var absoluteDistance : Float = 0.87

func absVal(_ param : Double) -> Double {
    if param < 0 {
        return -param
    }
    return param
}

protocol REMDelegate : class {
    func periodChanged(to new: Double)
    func playbackStopped()
}

// MARK: - Enums

enum Rhythmic : Int, Codable {
    case Bilateral = 0
    case Crosspan
    case Synthesis
    case Stitch //Swave
    
    func descriptor() -> String {
        switch self {
        case .Bilateral:
            return "Bilateral"
        case .Crosspan:
            return "Crosspan"
        case .Synthesis:
            return "Synthesis"
        case .Stitch:
            return "Swave"
        }
    }
}

enum PanRate : Int, Codable {
    case Half = 0
    case Normal
    case Double
    case Quad
    
    func descriptor() -> String {
        switch self {
        case .Half:
            return "0.5x"
        case .Normal:
            return "1x"
        case .Double:
            return "2x"
        case .Quad:
            return "4x"
        }
    }
}

let documentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!

//MARK: - PanAudioPlayer
class PanAudioPlayer: AVAudioPlayer {

    // MARK: - Property controls
    private var timer : Timer = Timer()
    private var period : Double
    var trackIndex : Int?
    
    // MARK: - Playback controls
    override func play() -> Bool {
        timer.fire()
        return super.play()
    }
    
    override func stop() {
        timer.invalidate()
        super.stop()
    }
    
    // MARK: - Rhythm controls
    
    func invalidateRhythm() {
        timer.invalidate()
    }
    
    func setupRhythm(_ opt: Rhythmic) {
        
        if (opt == .Bilateral) { //phi
            self.pan = -1
            self.timer = Timer.scheduledTimer(withTimeInterval: period, repeats: true, block: { (timer : Timer) -> Void in
            
                self.pan *= -1
            })
            
        }
        
        else if (opt == .Crosspan) { //delta
  
            self.pan = absoluteDistance
            self.timer = Timer.scheduledTimer(withTimeInterval: period, repeats: true, block: { (timer : Timer) -> Void in
                
                self.pan *= -1
                
            })
            
        } else if (opt == .Synthesis) { //sigma
            
            //pan = 0
            self.pan = 0
            self.timer = Timer.scheduledTimer(withTimeInterval: self.period, repeats: true, block: {(timer : Timer) -> Void in
                
                // do nothing
            })
            
        } else if (opt == .Stitch) { //gamma
            
            var wavelength : Double = 0
            self.timer = Timer.scheduledTimer(withTimeInterval: self.period, repeats: true, block: { (timer : Timer) -> Void in
                let newVal = Float(sin(wavelength))
                wavelength += (pi/16)
                guard absVal(Double(newVal)) < 0.9 else { return }
                self.pan = newVal
                
            
            })
        }

    }
    
    // MARK: - Inits
    init(contentsOf url: URL, period: Double) throws {
        self.period = period
        do {
            try super.init(contentsOf: url, fileTypeHint: url.pathExtension)
        } catch let error as NSError {
            throw error
        }
    }
}

// MARK: - TrackManager
class TrackManager {
    var tracks : [Track]
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
        
    init(tracks trackArr : [Track]) {
        tracks = trackArr
    }
    
    convenience init() {
        guard let trackArr = try? DataHandler().decodeJSONData() else {
            self.init(tracks: DataHandler().defaultTracks())
            return
        }
        self.init(tracks: trackArr)
    }
    
    deinit {
        try? dataHandler.encodeTracks(tracks)
    }
}

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
        }
        
        if !isPlaying {
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
            throw NSError(domain: "PHandlerQueuedTracksNil", code: 1, userInfo: nil)
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

//wouldn't it be nice if the TrackArray held the URLs (as string)
// title, period, category, url xxx extension
// user inserts title & can auto-periodize or custom period
// MARK: - Track
struct Track : Codable {
   
    var title : String
    var period : Double
    var category : String
    
    let fileName : String //includes extension
    
    var rhythm : Rhythmic
    var rate : PanRate
    
    var url : URL {
        get {
            return (DataHandler.documentsDirectory?.appendingPathComponent(fileName))!
        }
    }
    // MARK: - Audio player
    lazy var audioPlayer: PanAudioPlayer? = {
        do {
            let val = try PanAudioPlayer(contentsOf: self.url, period: self.period.toPanRate(self.rate))
            return val
        } catch {
            print(error)
            return nil
        }
        
    }()

    init(title : String, period : Double, category : String = "song", fileName : String, rhythm : Rhythmic = .Bilateral, rate : PanRate = .Normal) {
        
        self.title = title
        self.period = period
        self.category = category
        self.fileName = fileName
        self.rhythm = rhythm
        self.rate = rate
    }
}

extension Track : Equatable {
    
    static func == (lTrack : Track, rTrack : Track) -> Bool {
        return lTrack.title == rTrack.title && lTrack.period == rTrack.period && lTrack.category == rTrack.category && rTrack.fileName == lTrack.fileName
    }
}

extension Double {
    func toPanRate(_ rate : PanRate) -> Double {
        switch rate {
        case .Double:
            return self / 2
            
        case .Half:
            return self * 2
            
        case .Quad:
            return self / 4
            
        default:
            return self
        }
    }
}
// MARK: - ViewModel
struct ViewModel {
    var tracks = TrackManager()
    private var trackQueue = Queue()
    var queue : Queue {
        get {
            return trackQueue
        }
    }
 
    func detailString(for index: Index) -> String {
        let aTrack = tracks[index]
        let rhythm = aTrack.rhythm.descriptor()
        let rate : String = aTrack.rate.descriptor()
        
        let amendedPeriod = aTrack.period.toPanRate(aTrack.rate)
        let perStr = String(format: "%.3f", amendedPeriod)
        
        return "\(rhythm) : \(rate) : \(perStr)"
    }
    
    func title(for index : Index) -> String {
        return tracks[index].title
    }

    // MARK: - Setup cells
    private func setupSelectedCell(_ cell : UITableViewCell) {
        cell.accessoryType = .checkmark
        let color = UIColor(red: 1, green: 0.4, blue: 0.4, alpha: 1.0)
        cell.textLabel?.textColor = color
        cell.tintColor = color
    }
    
    private func setupUnselectedCell(_ cell : UITableViewCell) {
        cell.accessoryType = .none
        cell.textLabel?.textColor = UIColor.black
    }
    
    func setupCell(_ cell : UITableViewCell, forRow index : Index) {
        cell.textLabel!.text = tracks[index].title
        cell.detailTextLabel!.text = self.detailString(for: index)
        
        if queue.contains(index) {
            setupSelectedCell(cell)
        } else {
            setupUnselectedCell(cell)
        }
    }
    
    // MARK: - Playback
    /// Returns an instantiated `PlaybackHandler` object.
    func playbackHandler() throws -> PlaybackHandler  {
        do {
            return try PlaybackHandler(queue: queue, tracks: tracks)
        } catch {
            throw error
        }
    }
}
// MARK: - Queue
/// Type for queue construction to pass to PlaybackHandler
class Queue : Sequence, IteratorProtocol {
    typealias Element = Index
    
    var selectedTracks = [Index]()
    private var position : Position
    var queued : [Index]? {
        get {
            if isEmpty == true { return nil }
            return selectedTracks
        }
    }
    var isEmpty : Bool {
        get {
            return selectedTracks.isEmpty
        }
    }
    
    subscript(position : Position) -> Index {
        get {
            return selectedTracks[position]
        } set {
            selectedTracks[position] = newValue
        }
    }
    // MARK: - Iteration
    func next() -> Index? {
        if position == selectedTracks.endIndex-1 {
            return nil
        }
        defer { position += 1 }
        return selectedTracks[position]
    }
    
    
    // MARK: - Selected tracks
    func append(selected : Index) {
        selectedTracks.append(selected)
    }
    
    func append(all : [Index]) {
        selectedTracks.append(contentsOf: all)
    }
    
    func remove(selected : Index) -> Index? {
        if selectedTracks.contains(selected) {
            return selectedTracks.remove(at: selectedTracks.firstIndex(of: selected)!)
        }
        return nil
    }
    
    func removeAll() {
        selectedTracks.removeAll()
    }
    
    func contains(_ index : Index) -> Bool {
        return selectedTracks.contains(index)
    }
    
    // MARK: - Selected cells
    func cellSelected(at index : Index) {
        if selectedTracks.contains(index) {
            _ = self.remove(selected: index)
        } else {
            self.append(selected: index)
        }
    }
    
    /// Only append index if not already present; will not remove index if selected. Non-destructive.
    func safeSelectCell(at index : Index) {
        if !contains(index) {
            selectedTracks.append(index)
        }
    }
    
    fileprivate init() {
        position = 0
    }
}
