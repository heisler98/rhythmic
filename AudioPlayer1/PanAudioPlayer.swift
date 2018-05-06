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
import AudioKit
import os.log

// MARK: - Enums

enum Rhythmic : Int, Codable {
    case Bilateral
    case Crosspan
    case Synthesis
    case Stitch //volume
}

enum PanRate : Double, Codable {
    case Half = 0.5
    case Normal = 1
    case Double = 2
    case Quad = 4
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
        print("Period: \(self.period)")
        
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
// MARK: - AudioManager
class AudioManager : NSObject, AVAudioPlayerDelegate {
    
    // MARK: - Private property controls
    static let documentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let archiveURL = documentsDirectory.appendingPathComponent("tracks")
    static let sessionArchiveURL = documentsDirectory.appendingPathComponent("sessions")
    
    private var tracks : TrackArray //array of Track structs
    private var playIndices : Array<Int>? //array of selected (indexPath.row)
    
    private var sessions : [Session]
    private var currentSessionIndex : Int?
    
    private var masterVolume : Float = 1.0
    private var nowPlaying : PanAudioPlayer?
    private var playerArray : Array<PanAudioPlayer>
    
    private var queueReady: Bool?
    
    
    // MARK: - Settable controls
    var delegate : AudioManagerDelegate?
    
    // MARK: - Answering controller
    
    var trackCount : Int { /// return count for tracks
        
        get {
            return tracks.count
        }
    }
    
    var sessionCount : Int {
        
        get {
            return sessions.count
        }
    }
    
    var isPlaying : Bool {
        
        get {
            if (nowPlaying != nil) {
                return nowPlaying!.isPlaying
            };  return false
        }
    }
    
    var isPlayingSession : Bool {
        
        get {
            if isPlaying == false { return false }
            if currentSessionIndex != nil { return true }
            return false
        }
    }
    
    func title(forIndex: Int) -> String {
        
        let aTrack = tracks[forIndex]
        return aTrack.title
        
    }
    
    func rhythmRate(forIndex: Int) -> String {
        
        let aTrack = tracks[forIndex]
        var rhythm : String?
        var rate : String?
        
        switch aTrack.rhythm {
        
        case .Bilateral:
            rhythm = "Bilateral"
            break
            
        case .Crosspan:
            rhythm = "Crosspan"
            break
            
        case .Synthesis:
            rhythm = "Synthesis"
            break
            
        case .Stitch:
            rhythm = "Swave"
            break
            
        }
        var amendedPeriod : Double
        
        switch aTrack.rate {
            
        case .Half:
            rate = "0.5x"
            amendedPeriod = aTrack.period * 2
            break
            
        case .Normal:
            rate = "1x"
            amendedPeriod = aTrack.period
            break
            
        case .Double:
            rate = "2x"
            amendedPeriod = aTrack.period / 2
            break
            
        case .Quad:
            rate = "4x"
            amendedPeriod = aTrack.period / 4
            break

        }
        let perStr = String(format: "%.3f", amendedPeriod)
        
        return "\(rhythm!) : \(rate!) : \(perStr)"
    }
    
    func isQueued() -> Bool {
        
        if let retVal = self.queueReady {
            return retVal
        }
        
        return false
    }
    
    // MARK: - Playback controls
    
    func playback(queued: Array<Int>) -> Bool {
        
        var retVal : Bool
        
        if let indices = self.playIndices {
            if (indices != queued) {
                self.clearQueue()
                self.playIndices = queued
            }
        }
        
        guard let _ = playIndices else { return false }
        
        let firstIndex = playIndices![0] as Int
        let firstTrack : Track = tracks[firstIndex]
        
        var period = firstTrack.period
        
        switch firstTrack.rate {
        
            case .Double:
                period /= 2
                break
            
            case .Half:
                period *= 2
                break
            
            case .Quad:
                period /= 4
                break
            
            default:
                break
        }
        
        
        let url = firstTrack.getURL()
        
        do {
            let aPlayer = try PanAudioPlayer(contentsOf: url, period: period)
            aPlayer.delegate = self as AVAudioPlayerDelegate
            aPlayer.trackIndex = firstIndex
            aPlayer.setupRhythm(firstTrack.rhythm)
            aPlayer.volume = masterVolume
            nowPlaying = aPlayer
            
            if (playIndices!.count == 1) {
                aPlayer.numberOfLoops = -1
            }
            
            retVal = nowPlaying!.play()
            
            if (nowPlaying != nil) {
                //playIndices?.remove(at: 0)
                playerArray.append(nowPlaying!)
            }
            
        } catch {
            
            print(error)
            return false
        }
        
        
        if (queueReady != true) {
            
            if (queued.count > 0) {
                self.queueReady = true
            }
            
            
        }
        
        let background = DispatchQueue.global()
        
        background.async {
            self.queueReady = self.instantiatePlayers()
        }
        
        return retVal
        
    }
    
    func playSession(atIndex: Int) {
        
        clearQueue()
        if self.isPlaying == true { stopPlayback() }
        
        let theSession = self.sessions[atIndex]
        guard let track = theSession.tracks.first else { return }
        
        self.currentSessionIndex = atIndex
        
        var period = track.period
        
        switch track.rate {
            
        case .Double:
            period /= 2
            break
            
        case .Half:
            period *= 2
            break
            
        case .Quad:
            period /= 4
            break
            
        default:
            break
        }
        
        let url = track.getURL()
        
        do {
            let aPlayer = try PanAudioPlayer(contentsOf: url, period: period)
            aPlayer.delegate = self as AVAudioPlayerDelegate
            aPlayer.setupRhythm(track.rhythm)
            aPlayer.volume = masterVolume
            aPlayer.trackIndex = 0
            nowPlaying = aPlayer
            
            _ = nowPlaying!.play()
            
            if (nowPlaying != nil) {
                playerArray.append(nowPlaying!)
            }
            
        } catch {
            print(error)
        }
        
        let background = DispatchQueue.global(qos: .background)
        background.async {
            self.queueReady = self.instantiatePlayers(forSession: theSession)
            
        }
        
    }

    
    func stopPlayback() {
        
        guard let player = nowPlaying else { return }
        
        if (player.isPlaying == true) {
            player.stop()
        } 
    
    }
    
    func skipCurrentTrack() {
        
        guard let player = nowPlaying else { return }
        
        if (player.isPlaying == true) {
            player.stop()
        }
        
        self.audioPlayerDidFinishPlaying(player, successfully: false)
    }
    
    func togglePauseResume() {
        
        if (self.isPlaying == true) {
            if let player = nowPlaying {
                player.pause()
            }
            return
        }
        
        if (self.isPlaying == false) {
            if let player = nowPlaying {
                _ = player.play()
            }
        }
    }
    
    func updateVolume(_ level: Float) {
        
        masterVolume = level
        
        if (self.isPlaying == true) {
            if let player = self.nowPlaying {
                player.volume = masterVolume
            }
        }
    }
    
    // MARK: - Queue controls
    
    private func clearQueue() {
        
        self.playIndices = []
        self.playerArray = []
        nowPlaying = nil
        queueReady = nil
        currentSessionIndex = nil
    }
    
    func repeatQueue() {
        // are playSession:atIndex & playback:queued valid to use here, instead of single-loading the track?
        
        if (isQueued() == true) {
            
            var aTrack : Track?
            
            if currentSessionIndex != nil {
                let theSession = self.sessions[currentSessionIndex!]
                aTrack = theSession.tracks.first!
                
            } else {
                if let index = self.playIndices?.first {
                    aTrack = self.tracks[index]
                }
            }
            
            if let _ = aTrack {
                nowPlaying = self.playerArray[0]
                nowPlaying?.volume = masterVolume
                nowPlaying?.setupRhythm(aTrack!.rhythm)
                _ = nowPlaying?.play()
            }
        }
    }
    
    // MARK: - Track controls
    
    func add(newTrack : Track) {
        
        tracks.append(newTrack)
        _ = AudioManager.saveTracks(self.tracks)
    }
    
    func deleteTrack(atIndex index : Int) -> Bool {
        
        if tracks.indices.contains(index) {
            tracks.remove(at: index)
            return AudioManager.saveTracks(self.tracks)
        } else {
            print("Deletion index out of track range")
            return false
        }
    }
    
    static func saveTracks(_ tracks : [Track]) -> Bool {
        
        do {
            let data = try JSONEncoder().encode(tracks)
            FileManager.default.createFile(atPath: AudioManager.archiveURL.path, contents: data, attributes: nil)
        } catch let error {
            print("\(error)")
            return false
        }
        
        return true
    }
    
    static func loadTracks() -> [Track]? {
        
        if let data = FileManager.default.contents(atPath: AudioManager.archiveURL.path) {
            
            do {
                return try JSONDecoder().decode(TrackArray.self, from: data)
            } catch {
                print("\(error)")
                return nil
            }
        } else {
            return nil
        }
    }
    
    func setTracks(_ setup : [Track]) throws {
        
        if (self.tracks.isEmpty != false) {
            let error = NSError(domain: "AMPropertyTrackAlreadySet", code: 1, userInfo: nil)
            throw error
        }
        
        self.tracks = setup
    }
    
    func setRhythm(_ rhythm : Rhythmic, forIndex trackIndex : Int) {
        
        self.tracks[trackIndex].rhythm = rhythm
        _ = AudioManager.saveTracks(self.tracks)
    }
    
    func setRate(_ rate : PanRate, forIndex trackIndex : Int) {
        
        self.tracks[trackIndex].rate = rate
        _ = AudioManager.saveTracks(self.tracks)
    }
    
    private func instantiatePlayers() -> Bool { ///call async
        
        var success : Bool = true
        guard let _ = self.playIndices else { return false }
        
        for index in self.playIndices! where index != self.playIndices!.first! {
            
            let aTrack = self.tracks[index]
            var period = aTrack.period
            
            switch aTrack.rate {
                
            case .Double:
                period /= 2
                break
                
            case .Half:
                period *= 2
                break
                
            case .Quad:
                period /= 4
                break
                
            default:
                break
            }
            
            let url = aTrack.getURL()
        
            do {
                let aPlayer = try PanAudioPlayer(contentsOf: url, period: period)
                aPlayer.delegate = self as AVAudioPlayerDelegate
                //aPlayer.setupRhythm(aTrack.rhythm)
                aPlayer.trackIndex = index
                self.playerArray.append(aPlayer)
                
            } catch {
                print(error)
                success = false; return success
            }
        }
        return success
    }
    // MARK: - Session controls
    
    func createSession(_ queue: Array<Int>, named: String) {
        
        var someTracks : TrackArray = []
        for index in queue {
            let track = self.tracks[index]
            someTracks.append(track)
        }
        let aSession = Session(name: named, tracks: someTracks)
        self.sessions.append(aSession)
        _ = AudioManager.saveSessions(self.sessions)
    }
    
    func deleteSession(atIndex: Int) {
        
        self.sessions.remove(at: atIndex)
        _ = AudioManager.saveSessions(self.sessions)
    }
    
    static func loadSessions() -> [Session]? {
        
        if let data = FileManager.default.contents(atPath: AudioManager.sessionArchiveURL.path) {
            
            do {
                return try JSONDecoder().decode(Array<Session>.self, from: data)
            } catch {
                print("\(error)")
                return nil
            }
        }
        
        return nil
    }
    
    static func saveSessions(_ sessions : [Session]) -> Bool {
        
        do {
            let data = try JSONEncoder().encode(sessions)
            FileManager.default.createFile(atPath: AudioManager.sessionArchiveURL.path, contents: data, attributes: nil)
        } catch let error {
            print("\(error)")
            return false
        }
        
        return true
    }
    
    func setSessions(_ someSessions : [Session]) throws {
        
        if self.sessionCount != 0 {
            let error = NSError(domain: "AMPropertySessionsAlreadySet", code: 2, userInfo: nil)
            throw error
        }
        
        self.sessions = someSessions
    }
    
    func sessionInformation(forIndex: Int) -> (String, Int) {
        let aSession = self.sessions[forIndex]
        return (aSession.name, aSession.tracks.count)
    }
    
    
    private func instantiatePlayers(forSession aSession: Session) -> Bool {
        
        var success : Bool?
        
        var allTracks = aSession.tracks
        allTracks.remove(at: 0)
        
        for track in allTracks {
            
            var period = track.period
            
            switch track.rate {
                
            case .Double:
                period /= 2
                break
                
            case .Half:
                period *= 2
                break
                
            case .Quad:
                period /= 4
                break
                
            default:
                break
            }
            
            let url = track.getURL()
            
            do {
                let aPlayer = try PanAudioPlayer(contentsOf: url, period: period)
                aPlayer.delegate = self as AVAudioPlayerDelegate
                aPlayer.volume = masterVolume
                aPlayer.trackIndex = aSession.tracks.index(of: track)
                playerArray.append(aPlayer)
                
                success = true
                
            } catch {
                print(error)
                success = false
            }
        }
        
        guard let _ = success else { return false }
        return success!
    }
    
    // MARK: - PanAudioPlayer delegate controls
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
     
            guard let audioPlayer = player as? PanAudioPlayer else { return }
        
            audioPlayer.invalidateRhythm()
        
            guard let currentIndex = self.playerArray.index(of: audioPlayer) else {
                self.delegate?.audioManagerPlaybackInterrupted()
                return
            }
            
            if (currentIndex == (playerArray.count-1)) {
                
                
                    if (self.delegate != nil) {
                        
                        self.delegate!.audioManagerDidCompletePlaylist()
                    }
                return
            }
            
            if (queueReady == true) {
            
                let nextPlayer = self.playerArray[currentIndex+1] as PanAudioPlayer
                nextPlayer.volume = masterVolume
                guard let index = nextPlayer.trackIndex else { return }
                
                if (currentSessionIndex == nil) {
                    nextPlayer.setupRhythm(self.tracks[index].rhythm)
                    
                } else {
                    let session = self.sessions[currentSessionIndex!]
                    nextPlayer.setupRhythm(session.tracks[index].rhythm)
                }
                
                _ = nextPlayer.play()
                nowPlaying = nextPlayer
                
            }
        
    }
    
    // MARK: - Initializers
    
    override init() {
        playIndices = Array()
        playerArray = Array()
        tracks = AudioManager.loadTracks() ?? TrackArray()
        sessions = AudioManager.loadSessions() ?? []
        
        super.init()
    }

}
// MARK: - AudioManagerDelegate
protocol AudioManagerDelegate {
    func audioManagerDidCompletePlaylist()
    func audioManagerPlaybackInterrupted()
}

//wouldn't it be nice if the TrackArray held the URLs (as string)
// title, period, category, url xxx extension
// user inserts title & can auto-periodize or custom period

struct Track : Codable {
   
    var title : String
    var period : Double
    var category : String
    
    let fileName : String //includes extension
    
    var rhythm : Rhythmic
    var rate : PanRate
    
    func getURL() -> URL {
        return AudioManager.documentsDirectory.appendingPathComponent(fileName)
    }
    
}

extension Track : Equatable {
    
    static func == (lTrack : Track, rTrack : Track) -> Bool {
        return lTrack.title == rTrack.title && lTrack.period == rTrack.period && lTrack.category == rTrack.category && rTrack.fileName == lTrack.fileName
    }
}

struct Session : Codable {
    
    var name : String
    var tracks : TrackArray
    
}
