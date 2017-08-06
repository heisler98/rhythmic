//
//  PanAudioPlayer.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 7/14/17.
//  Copyright © 2017 Hunter Eisler. All rights reserved.
//

import UIKit
import AVFoundation

private enum PanDirection {
    case Left
    case Right
}

typealias MusicFileDictionary = DictionaryLiteral<Array<String>, Array<URL>>  //<title, URL path>


class PanAudioPlayer: AVAudioPlayer {

    private var timer : Timer = Timer()
    private var direction : PanDirection = .Left
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
    
    func invalidatePan() {
        
        timer.invalidate()
    }
    
    init(contentsOf url: URL, period: Double) throws {
        
        self.period = period
        
        do {
            try super.init(contentsOf: url, fileTypeHint: url.pathExtension)
            
        
        } catch let error as NSError {
            throw error
        }
        
        
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
}

class AudioManager : NSObject, AVAudioPlayerDelegate {
    
    
    
    private var keys : Array<String>?
    private var players : Dictionary<String, PanAudioPlayer>?     //'Literal' implies ordered
                                                                  // <title, Player instance>
    

    private var nowPlaying : PanAudioPlayer?
    private var currentIndex : Int = 0
    var repeatOn : Bool?
    var delegate : AudioManagerDelegate?
    
    var playerCount : Int {
        
        get {
            if (keys != nil) { return keys!.count }
            return 0
        }
    }
    
    var isPlaying : Bool {
        
        get {
            if (nowPlaying != nil) {
                return nowPlaying!.isPlaying
            };  return false
        }
    }
    
    private func play(atIndex: Int) -> Bool {
        
        nowPlaying = nil
        let key = keys![atIndex]
        nowPlaying = players?[key]
        
        currentIndex = atIndex
        
        return (nowPlaying?.play())!
        
    }
    
    func beginPlayback() -> Bool {
        
        return self.play(atIndex: 0)
        
    }
    
    func resumePlayback() -> Bool {
        
        if (nowPlaying != nil && nowPlaying?.isPlaying == false) {
            return nowPlaying!.play()
        }
        
        if (nowPlaying == nil) {
            return self.play(atIndex: currentIndex)
        }
        
        return false
    }
    
    func pause() {
        
        if (nowPlaying?.isPlaying == true) {
            nowPlaying?.pause()
        }
    }
    
    func stop(andReset: Bool) {
        
        if (nowPlaying?.isPlaying == true) {
            nowPlaying?.stop()
        }
        
        if (andReset == true) {
            currentIndex = 0
        }
    }
    
    init(withDictionary: MusicFileDictionary, repeating : Bool, panTimes : Array<Double>) throws {
    //should throw exception if a player fucks up 
        
        super.init()
        var count = 0       // usage: panTimes[count]
        
        // should use background processing...?
        players = [:]
        keys = []
        repeatOn = repeating
        var urls : Array<URL>?
        
        for element in withDictionary {         // if dictionary passed correctly, will iterate once
            keys = element.key
            urls = element.value
        }
        
        
        for url in urls! {
            
            do {
                
                let player = try PanAudioPlayer(contentsOf: url, period: panTimes[count])
                player.delegate = self as AVAudioPlayerDelegate
            
                self.players?.updateValue(player, forKey: keys![count])
    
                count += 1
            
            } catch let error as NSError {
         
                print("Cannot create instance of PanAudioPlayer; check URL path: \(error.code)")
                throw error
            }
            
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
     
        let nextIndex = currentIndex + 1
        nowPlaying = nil
        
        let panPlayer : PanAudioPlayer = player as! PanAudioPlayer
        panPlayer.invalidatePan() //stops the timer
        
        if ((players?.count)! > currentIndex + 1) {    // players to continue to play
            
            _ = self.play(atIndex: nextIndex)
            return
        }
            
        if (repeatOn == true) {
            if (self.delegate != nil) {
                self.delegate!.audioManagerDidCompletePlaylist()
            }
        }
    }
    
    
    
    
    
    
}

protocol AudioManagerDelegate {
    func audioManagerDidCompletePlaylist()
}
