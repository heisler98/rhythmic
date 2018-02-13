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
import os.log

private enum PanDirection {
    case Left
    case Center
    case Right
    case MidLeft
    case MidRight
}

enum Rhythmic {
    case Bilateral
    case Crosspan
    case Synthesis
    case Stitch //volume
}

enum PanRate {
    case Half
    case Normal
    case Double
    case Quad
}

let documentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!

class PanAudioPlayer: AVAudioPlayer {

    private var timer : Timer = Timer()
    private var direction : PanDirection = .Left
    private var lastDirection = PanDirection.Left
    private var counter = 0
    private var period : Double
    
    
    override func play() -> Bool {
    
        
        timer.fire()
        print("Period: \(self.period)")
        
        return super.play()
        
    }
    
    override func stop() {
        timer.invalidate()
        super.stop()
    }
    
    func invalidateRhythm() {
        
        timer.invalidate()
    }
    
    func setupRhythm(_ opt: Rhythmic) {
        
        if (opt == .Bilateral) { //phi
        
            self.timer = Timer.scheduledTimer(withTimeInterval: period, repeats: true, block: { (timer : Timer) -> Void in
            
                if self.direction == PanDirection.Left {
                
                    self.pan = 1.0
                    self.direction = .Right
                
                } else {
                
                    self.pan = -1.0
                    self.direction = .Left
                }
            
            
            })
            
        }
        
        else if (opt == .Crosspan) { //delta
  

            self.timer = Timer.scheduledTimer(withTimeInterval: period, repeats: true, block: { (timer : Timer) -> Void in
                
                switch self.direction {
                    
                case PanDirection.Left:
                    // go to center
                    self.pan = 0
                    self.lastDirection = .Left
                    self.direction = .Center
                    break
                    
                case PanDirection.Center:
                    //go to left | right
                    if (self.lastDirection == .Left) {
                        //go to right
                        self.pan = 1.0
                        self.direction = .Right
                        break
                    }
                    //go to left
                    self.pan = -1
                    self.direction = .Left
                    break
                    
                case PanDirection.Right:
                    //go to center
                    self.pan = 0
                    self.lastDirection = .Right
                    self.direction = .Center
                    break
                    
                default:
                    print("error")
                    break
                }
                
            })
            
        } else if (opt == .Synthesis) { //sigma
            
            //pan = 0
            self.timer = Timer.scheduledTimer(withTimeInterval: self.period, repeats: true, block: {(timer : Timer) -> Void in
                
                // do nothing
            })
            
        } else if (opt == .Stitch) {
            
            self.timer = Timer.scheduledTimer(withTimeInterval: self.period, repeats: true, block: { (timer : Timer) -> Void in
                
                //left = on; right = off
                if (self.direction == .Left) {
                    self.volume = 1.0
                    self.direction = .Right
                } else if (self.direction == .Right) {
                    self.volume = 0.0
                    self.direction = .Left
                }
            
            })
        }

    }
    
    
    init(contentsOf url: URL, period: Double) throws {
        
        self.period = period
        
        do {
            try super.init(contentsOf: url, fileTypeHint: url.pathExtension)
            
        } catch let error as NSError {
            throw error
        }
        
    }
}

class AudioManager : NSObject, AVAudioPlayerDelegate, NSCoding {
    
    // MARK: - Private property controls
    static let documentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let archiveURL = documentsDirectory.appendingPathComponent("tracks")
    
    private var tracks : TrackArray //array of dictionaries containing <String, String>
    private var playIndices : Array<Int>? //array of selected (indexPath.row)
    
    
    private var masterVolume : Float = 1.0
    private var nowPlaying : PanAudioPlayer?
    private var playerArray : Array<PanAudioPlayer>
    
    private var queueReady: Bool?
    
    // MARK: - Settable controls
    var rhythm : Rhythmic = .Bilateral
    var rate : PanRate = .Normal
    var delegate : AudioManagerDelegate?
    
    // MARK: - Answering controller
    
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
        
        let trackDict = tracks[forIndex]
        return trackDict["title"]!
        
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
        let firstTrack : Dictionary<String, String> = tracks[firstIndex]
        
        var period = Double(firstTrack["period"]!)
        
        switch rate {
        
            case .Double:
                period! /= 2
                break
            
            case .Half:
                period! *= 2
                break
            
            case .Quad:
                period! /= 4
                break
            
            default:
                break
        }
        
        let lastComponent = firstTrack["title"]! + "." + firstTrack["extension"]!
        let url = AudioManager.documentsDirectory.appendingPathComponent(lastComponent)
        
        do {
            let aPlayer = try PanAudioPlayer(contentsOf: url, period: period!)
            aPlayer.delegate = self as AVAudioPlayerDelegate
            aPlayer.setupRhythm(rhythm)
            aPlayer.volume = masterVolume
            nowPlaying = aPlayer
            
            retVal = nowPlaying!.play()
            
            if (nowPlaying != nil) {
                playIndices?.remove(at: 0)
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
    
    
    func stopPlayback() {
        
        guard let player = nowPlaying else { return }
        
        if (player.isPlaying == true) {
            player.stop()
        } 
    
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
        
        if (isQueued() == true) {
            nowPlaying = self.playerArray[0]
            stopPlayback()
            nowPlaying?.setupRhythm(rhythm)
            nowPlaying?.volume = masterVolume
            _ = nowPlaying?.play()
            
        }
        
    }
    
    // MARK: - Track controls
    
    func add(newTrack : TrackArray) {
        
        tracks.append(newTrack.first!)
        
    }
    
    private func instantiatePlayers() -> Bool { ///call async
        
        var success : Bool = true
        guard let _ = self.playIndices else { return false }
        
        for index in self.playIndices! {
            
            let trackDict = self.tracks[index]
            var period = Double(trackDict["period"]!)
            
            switch rate {
                
            case .Double:
                period! /= 2
                break
                
            case .Half:
                period! *= 2
                break
                
            case .Quad:
                period! /= 4
                break
                
            default:
                break
            }
            
            let lastComponent = trackDict["title"]! + "." + trackDict["extension"]!
            let url = AudioManager.documentsDirectory.appendingPathComponent(lastComponent)
        
            do {
                let aPlayer = try PanAudioPlayer(contentsOf: url, period: period!)
                aPlayer.delegate = self as AVAudioPlayerDelegate
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
            
                let nextPlayer = self.playerArray[currentIndex+1]
                nextPlayer.setupRhythm(rhythm)
                nextPlayer.volume = masterVolume
                _ = nextPlayer.play()
                nowPlaying = nextPlayer
                
                
            }
        
    }
    
    // MARK: - Initializers
    
    init(withArray: TrackArray) {
        
        playIndices = Array()
        playerArray = Array()
        tracks = withArray
        
        super.init()
        
    }
    
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.tracks, forKey: "kStoreTrackArray")
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        guard let trackArr = aDecoder.decodeObject(forKey: "kStoreTrackArray") as? TrackArray else {
            print("Cannot decode kStoreTrackArray")
            return nil
        }
        
        self.init(withArray: trackArr)
    }

}

protocol AudioManagerDelegate {
    func audioManagerDidCompletePlaylist()
    func audioManagerPlaybackInterrupted()
}

//wouldn't it be nice if the TrackArray held the URLs (as string)
// title, period, category, url xxx extension
// user inserts title & can auto-periodize or custom period

// we will need a sessions manager

class SessionManager : AudioManager {
    
}
