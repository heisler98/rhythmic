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
}


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
  
/*
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
 
 */
      /*
            self.timer = Timer.scheduledTimer(withTimeInterval: (period/2), repeats: true, block: { (timer) -> Void in
                
                switch self.direction {
                    
                case PanDirection.Left:
                    if (self.lastDirection == .MidLeft) {
                        self.pan = -1.0
                        self.lastDirection = .Left
                        self.direction = .Left //to repeat 'Left'
                    }
                    
                    if (self.lastDirection == .Left) {
                        //go to MidLeft
                        self.pan = -0.33
                        self.lastDirection = .Left
                        self.direction = .MidLeft
                    }
                    break
                    
                case PanDirection.MidLeft:
                    if (self.lastDirection == .Left) {
                        self.pan = 0.33
                        self.lastDirection = .MidLeft
                        self.direction = .MidRight
                    }
                    if (self.lastDirection == .MidRight) {
                        self.pan = -1.0
                        self.lastDirection = .MidLeft
                        self.direction = .Left
                    }
                    break
                    
                case PanDirection.MidRight:
                    if (self.lastDirection == .Right) {
                        self.pan = -0.33
                        self.lastDirection = .MidRight
                        self.direction = .MidLeft
                    }
                    if (self.lastDirection == .MidLeft) {
                        self.pan = 1.0
                        self.lastDirection = .MidRight
                        self.direction = .Right
                    }
                    break
                    
                case PanDirection.Right:
                    if (self.lastDirection == .MidRight) {
                        self.pan = 1.0
                        self.lastDirection = .Right
                        self.direction = .Right //to repeat 'Right'
                    }
                    if (self.lastDirection == .Right) {
                        self.pan = 0.33
                        self.lastDirection = .Right
                        self.direction = .MidRight
                    }
                    break
                    
                default:
                    print("error")
                    break
                }
                
            })
            
            */
            
            self.timer = Timer.scheduledTimer(withTimeInterval: period, repeats: true, block: { (timer) -> Void in
                
                switch self.direction {
                    
                case .Left:
                    
                    if (self.lastDirection == .Center) {
                        self.pan = 1
                        self.lastDirection = .Left
                        self.direction = .Right
                        self.counter = 1
                        break
                    }
                    
                    if (self.lastDirection == .Right) {
                        
            
                            self.pan = 1
                            self.lastDirection = .Left
                            self.direction = .Right
                            self.counter += 1
                            break
                        
                    }
                    
                    if (self.lastDirection == .Left) {
                        self.pan = 1
                        self.direction = .Right
                        break
                    }
                    break
                    
                case .Right:
                    
                    if (self.counter < 2) {
                        self.pan = -1
                        self.lastDirection = .Right
                        self.direction = .Left
                        self.counter += 1
                        break
                    }
                    
                    if (self.counter >= 2) { //switch to .Center
                        self.pan = 0
                        self.lastDirection = .Right
                        self.direction = .Center
                        self.counter = 0
                        break
                    }
                    
                    break
                    
                case .Center:
                    
                    switch self.counter {
                        
                    case 0:
                        self.pan = 0
                        self.lastDirection = .Center
                        self.counter = 1
                        
                        break
                        
                    case 1:
                        self.pan = 0
                        self.lastDirection = .Center
                        self.counter = 2
                        break
                        
                    case 2:
                        self.pan = 0
                        self.lastDirection = .Center
                        self.counter = 3
                        break
                        
                    default:
                        self.pan = -1
                        self.direction = .Left
                        self.counter = 0
                        
                        break
                    }
                    
                    break
                    
                default:
                    break
                    
                }
                
            })
            
            
        } else if (opt == .Synthesis) { //sigma
            
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

class AudioManager : NSObject, AVAudioPlayerDelegate {
    
    
    private var tracks : TrackArray //array of dictionaries containing <String, String>
    private var playIndices : Array<Int>? //array of selected (indexPath.row)
    
    
    private var nowPlaying : PanAudioPlayer?
    private var playerArray: Array<PanAudioPlayer>
    
    private var queueReady: Bool?
    var rhythm: Rhythmic = .Bilateral
            var delegate : AudioManagerDelegate?
    
    
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
        
        let period = Double(firstTrack["period"]!)
        
        let url = Bundle.main.url(forResource: firstTrack["title"]!, withExtension: "mp3")
        
        do {
            let aPlayer = try PanAudioPlayer(contentsOf: url!, period: period!)
            aPlayer.delegate = self as AVAudioPlayerDelegate
            aPlayer.setupRhythm(rhythm)
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
        
        if (nowPlaying?.isPlaying == true) {
            nowPlaying?.stop()
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
    
    
    private func clearQueue() {
        
        self.playIndices = []
        self.playerArray = []
        nowPlaying = nil
        queueReady = nil
        
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
    
    private func instantiatePlayers() -> Bool { ///call async
        
        var success : Bool = true
        guard let _ = self.playIndices else { return false }
        
        for index in self.playIndices! {
            
            let trackDict = self.tracks[index]
            let fileName = trackDict["title"]!
            let period = Double(trackDict["period"]!)
            
            guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else { success = false; return success }
            
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
    
    init(withArray: TrackArray) {
 
        playIndices = Array()
        playerArray = Array()
        tracks = withArray
        
        super.init()
        
    }

    func repeatQueue() {
    
        if (isQueued() == true) {
            nowPlaying = self.playerArray[0]
            stopPlayback()
            nowPlaying?.setupRhythm(rhythm)
            _ = nowPlaying?.play()
            
        }
        
    }
    
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
                _ = nextPlayer.play()
                nowPlaying = nextPlayer
                
                
            }
        
    }
}

protocol AudioManagerDelegate {
    func audioManagerDidCompletePlaylist()
    func audioManagerPlaybackInterrupted()
}
