//
//  ViewController.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 11/3/16.
//  Copyright © 2016 Hunter Eisler. All rights reserved.
//
// so i learn'd what I did was hodgepodge

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    
    private var defaultManager : AudioManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            UIApplication.shared.beginReceivingRemoteControlEvents()
            
            NotificationCenter.default.addObserver(self, selector: #selector(ViewController.audioSessionInterrupted), name: NSNotification.Name.AVAudioSessionInterruption, object: self)
            

            
        } catch let error as NSError {
            print("error: \(error)")
        }
        
        
    
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        self.playAllFiles()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func playAllFiles() {
        
        let hurtURL = Bundle.main.url(forResource: "Let's Hurt Tonight", withExtension: "m4a")
        let bornURL = Bundle.main.url(forResource: "Born", withExtension: "mp3")
        let betterURL = Bundle.main.url(forResource: "Better", withExtension: "m4a")
        let humanURL = Bundle.main.url(forResource: "Human", withExtension: "m4a")
        let loseURL = Bundle.main.url(forResource: "If I Lose Myself", withExtension: "mp3")
        let liftURL = Bundle.main.url(forResource: "Lift Me Up", withExtension: "m4a")
        let heavenURL = Bundle.main.url(forResource: "Heaven", withExtension: "m4a")
        let livedURL = Bundle.main.url(forResource: "I Lived", withExtension: "mp3")
        let startURL = Bundle.main.url(forResource: "Start Over", withExtension: "mp3")
        let marchinURL = Bundle.main.url(forResource: "Marchin On", withExtension: "m4a")
        
        let hurtStr = hurtURL?.pathComponents.last?.components(separatedBy: ".")[0]
        let bornStr = bornURL?.pathComponents.last?.components(separatedBy: ".")[0]
        let betterStr = betterURL?.pathComponents.last?.components(separatedBy: ".")[0]
        let humanStr = humanURL?.pathComponents.last?.components(separatedBy: ".")[0]
        let loseStr = loseURL?.pathComponents.last?.components(separatedBy: ".")[0]
        let liftStr = liftURL?.pathComponents.last?.components(separatedBy: ".")[0]
        let heavenStr = heavenURL?.pathComponents.last?.components(separatedBy: ".")[0]
        let livedStr = livedURL?.pathComponents.last?.components(separatedBy: ".")[0]
        let startStr = startURL?.pathComponents.last?.components(separatedBy: ".")[0]
        let marchinStr = marchinURL?.pathComponents.last?.components(separatedBy: ".")[0]
        
        let dictionary : MusicFileDictionary = [hurtStr! : hurtURL!,
                                                bornStr! : bornURL!,
                                                betterStr! : betterURL!,
                                                humanStr! : humanURL!,
                                                loseStr! : loseURL!,
                                                liftStr! : liftURL!,
                                                heavenStr! : heavenURL!,
                                                livedStr! : livedURL!,
                                                startStr! : startURL!,
                                                marchinStr! : marchinURL!]
        
        var periods : Array<Double> = []
        for number in 0...9 {
            periods.append(self.period(forIndex: number))
        }
        
        do {
            defaultManager = try AudioManager(withDictionary: dictionary, repeating: true, panTimes: periods)
        } catch _ as NSError {
            //refer to `AudioManager(withDictionary:repeating:panTimes:)` for error
        }
        
        if (defaultManager != nil) {
            _ = defaultManager!.beginPlayback()
        }
        

        
        
    }
    
    override func remoteControlReceived(with event: UIEvent?) {
        
        if event?.type == UIEventType.remoteControl {
            
            switch event!.subtype {
            case UIEventSubtype.remoteControlTogglePlayPause:
                
                break
            default:
                break
            }
        }
        
    }
    
    func audioSessionInterrupted() {
        
   }
    
    @IBAction func info(_ sender: Any) {
        
        // create UIAlertView to show std. osc. period for each song
        // Let's Hurt Tonight: 65bpm (subd.) -> 0.92 sec/osc
        // Born : 95bpm (subd.) -> 0.63 sec/osc OR 0.833 sec/osc
        // Lions : 96bpm (subd.) -> 0.625 sec/osc OR 0.833 sec/osc
        // Silence: 82bpm (subd.) -> 0.73 sec/osc
        // Love/Drugs: 128bpm -> 0.46875 sec/osc
        // I Lived: 120bpm -> 0.5 sec/osc
        // Start Over : 98bpm -> 0.61 sec/osc
        /*
         Better .88
         Human  .43
         Lift   .52
         Heaven .63
         Start  .61
        
        */
        let message = String.init(stringLiteral: "Let's Hurt Tonight: 65bpm 0.92 \n Born: 95bpm 0.63|0.83 \n Better: 0.88 \n Human: 0.43 \n Lift Me Up: 0.53 \n Heaven: 0.63 \n I Lived: 0.50 \n Start Over: 0.61 \n Marchin On: 0.49")
        
        let alert = UIAlertController(title: "Oscillations", message: message, preferredStyle: UIAlertControllerStyle.alert)
        let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
        
        alert.addAction(action)
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func period(forIndex: Int) -> Double {
        
        switch forIndex {
            
        case 0:
            return 0.92 //Let's Hurt Tonight
            
        case 1:
            return 0.63 //Born
            
        case 2:
            return 0.88 //Better
            
        case 3:
            return 0.43 //Human
            
        case 4:
            return 0.42 //If I Lose Myself
            
        case 5:
            return 0.53 //Lift Me Up
        
        case 6:
            return 0.63 //Heaven
            
        case 7:
            return 0.50 //I Lived
            
        case 8:
            return 0.61 //Start Over
            
        case 9:
            return 0.49 //Marchin On
            
        default:
            return 0.0
            
        }
        
    }

    
}

