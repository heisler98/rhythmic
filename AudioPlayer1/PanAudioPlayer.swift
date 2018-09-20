//
//  PanAudioPlayer.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 7/14/17.
//  Copyright © 2017 Hunter Eisler. All rights reserved.
//  Unauthorized copying of this file via any medium is strictly prohibited.
//  *Proprietary and confidential*

#if os(iOS)
import UIKit
#endif

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
}

enum PanRate : Int, Codable {
    case Half = 0
    case Normal
    case Double
    case Quad
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
    
    static let documentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let archiveURL = documentsDirectory.appendingPathComponent("tracks")
    
    static let shared = AudioManager()
    
    lazy var entrainer = Entrainment()
    
    // MARK: - Private property controls
    private var tracks : TrackArray //array of Track structs
    private var playIndices : Array<Int>? //array of selected (indexPath.row)
    
    private var masterVolume : Float = 1.0
    private var nowPlaying : PanAudioPlayer?
    private var playerArray : Array<PanAudioPlayer>
    
    private var queueReady: Bool?
    
#if os(iOS)
    private let nowPlayingCenter = MPNowPlayingInfoCenter.default()
#endif
    
    // MARK: - Settable controls
    weak var delegate : AudioManagerDelegate?
    weak var remDelegate : REMDelegate?
    /// Choose entrainment to play with tracks (optional)
    var entrain : EntrainmentType? = nil {
        willSet {
            if newValue == nil {
                entrainer.stopAudio()
            }
        }
    }
    // MARK: - Answering Rhythmic controller
    
    var trackCount : Int { /// return count for tracks
        get {
            return tracks.count
        }
    }
    var isPlaying : Bool {
        get {
            if (nowPlaying != nil) {
                return nowPlaying!.isPlaying
            };  return false
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
    
    // MARK: - Answering Session controller
    
    var selectedTracks : [Int] {
        get {
            return checkedTracks
        }
    }
    
    private var checkedTracks : [Int] = [Int]()
    
    func rate(forIndex index : Int) -> PanRate {
        return self.tracks[index].rate
    }
    
    func rhythm(forIndex index : Int) -> Rhythmic {
        return self.tracks[index].rhythm
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
        
        
        let url = firstTrack.url
        
        do {
            #if os(iOS)
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.default)
            try AVAudioSession.sharedInstance().setActive(true)
            #endif
            
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
            
            // entrainment
            if entrain != nil && !entrainer.isPlaying {
                switch entrain! {
                case nil:
                    break
                    
                case .Binaural(let freq):
                    entrainer.binaural(midFrequency: NSNumber(value: freq))
                    break
                    
                case .Bilateral(let freq, let period):
                    let periodVal : Double
                    if period == 0 {
                        periodVal = firstTrack.period
                    } else {
                        periodVal = period
                    }
                    entrainer.bilateral(tonalFrequency: NSNumber(value: freq), period: NSNumber(value: periodVal))
                    break
                    
                case .Isochronic(let freq, let wave):
                    entrainer.isochronic(tonalFrequency: NSNumber(value: freq), brainwaveTarget: NSNumber(value: wave))
                    break
                }
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

        #if os(iOS)
        UIApplication.shared.beginReceivingRemoteControlEvents()
        updateNowPlayingCenter(nowPlayingCenter, withTrackAtIndex: firstIndex)
        #endif
        
        return retVal
        
    }
    
    func stopPlayback() {
        
        guard let player = nowPlaying else { return }
        
        if (player.isPlaying == true) {
            player.stop()
            
            if entrainer.isPlaying == true {
                entrainer.stopAudio()
            }
            
            #if os(iOS)
            UIApplication.shared.endReceivingRemoteControlEvents()
            #endif
        } 
    
    }
    
    func skipCurrentTrack() {
        
        guard let player = nowPlaying else { return }
        
        if (player.isPlaying == true) {
            player.stop()
            player.currentTime = 0
        }
        
        self.audioPlayerDidFinishPlaying(player, successfully: true)
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
        
    }
    
    func repeatQueue() {
        // are playSession:atIndex & playback:queued valid to use here, instead of single-loading the track?
        // the players are already instantiated...
        
        if (isQueued() == true) {
            
            var aTrack : Track?
        
            if let index = self.playIndices?.first {
                    aTrack = self.tracks[index]
                }
            
            
            if let _ = aTrack {
                nowPlaying = self.playerArray[0]
                nowPlaying?.volume = masterVolume
                nowPlaying?.setupRhythm(aTrack!.rhythm)
                _ = nowPlaying?.play()
                #if os(iOS)
                updateNowPlayingCenter(nowPlayingCenter, withTrackAtIndex: self.playIndices!.first!)
                #endif
            }
        }
    }
    

    // MARK: - Session controls
    
    func moveTrackAt(index fromIndex : Int, toIndex : Int) {
        
        let trackToMove = checkedTracks.remove(at: fromIndex)
        checkedTracks.insert(trackToMove, at: toIndex)
        
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
    
    func setRhythm(_ rhythm : Rhythmic, forIndex trackIndex : Int) -> Bool {
        if rhythm == self.tracks[trackIndex].rhythm {
            return false
        }
        self.tracks[trackIndex].rhythm = rhythm
        return AudioManager.saveTracks(self.tracks)
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
            
            let url = aTrack.url
        
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
                
                nextPlayer.setupRhythm(self.tracks[index].rhythm)
                remDelegate?.periodChanged(to: self.tracks[index].period)
                _ = nextPlayer.play()
                nowPlaying = nextPlayer
                
                if case .Bilateral( _, _)? = entrain {
                    do {
                        try entrainer.changeBilateralPeriod(to: NSNumber(value: self.tracks[index].period))
                    } catch {
                        print(error)
                    }
                }
                
                #if os(iOS)
                updateNowPlayingCenter(nowPlayingCenter, withTrackAtIndex: index)
                #endif
            }
        
    }
    #if os(iOS)
    func updateNowPlayingCenter(_ center: MPNowPlayingInfoCenter, withTrackAtIndex index : Int) {
        let track = self.tracks[index]
        
        center.nowPlayingInfo = [MPMediaItemPropertyTitle : track.title, MPMediaItemPropertyAlbumTitle : "Rhythmic", MPNowPlayingInfoPropertyElapsedPlaybackTime : self.nowPlaying!.currentTime, MPNowPlayingInfoPropertyExternalUserProfileIdentifier : "rhythmic"]
    }
    
    func setupRemoteControlEvents() {
        
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.pauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.togglePauseResume()
            return .success
        }
        
        commandCenter.playCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.togglePauseResume()
            return .success
        }
        
        commandCenter.nextTrackCommand.addTarget(handler: {(event) -> MPRemoteCommandHandlerStatus in
            
            self.skipCurrentTrack()
            return .success
            
        })
    }
    #endif
    
    // MARK: - Initializers
    
    override private init() {
        playIndices = Array()
        playerArray = Array()
        tracks = AudioManager.loadTracks() ?? TrackArray()
        
        super.init()
        
    }

}

#if os(iOS)
extension AudioManager : SessionDelegate {
    func getPeriod() -> Double {
        guard let _ = nowPlaying?.trackIndex else { return 0 }
        return self.tracks[nowPlaying!.trackIndex!].period
    }
    
    func getRate() -> PanRate {
        guard let _ = nowPlaying?.trackIndex else { return PanRate.Normal }
        return self.tracks[nowPlaying!.trackIndex!].rate
    }

}
#endif

// MARK: - AudioManagerDelegate
protocol AudioManagerDelegate: class {
    func audioManagerDidCompletePlaylist()
    func audioManagerPlaybackInterrupted()
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
            return AudioManager.documentsDirectory.appendingPathComponent(fileName)
        }
    }
}

extension Track : Equatable {
    
    static func == (lTrack : Track, rTrack : Track) -> Bool {
        return lTrack.title == rTrack.title && lTrack.period == rTrack.period && lTrack.category == rTrack.category && rTrack.fileName == lTrack.fileName
    }
}
