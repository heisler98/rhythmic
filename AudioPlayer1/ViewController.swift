//
//  ViewController.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 11/3/16.
//  Copyright © 2016 Hunter Eisler. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, AVAudioPlayerDelegate {
    
    @IBOutlet weak var textBox : UITextField?
    @IBOutlet weak var pickerView : UIPickerView?
    @IBOutlet weak var repeatSwitch : UISwitch?
    
    var timer : Timer?
    
    var hurtPlayer  :   AVAudioPlayer?
    var bornPlayer  :   AVAudioPlayer?
    var betterPlayer :   AVAudioPlayer?
    var humanPlayer : AVAudioPlayer?
    var losePlayer :    AVAudioPlayer?
    var tonePlayer :    AVAudioPlayer?
    var liftPlayer :    AVAudioPlayer?
    var heavenPlayer :   AVAudioPlayer?
    var livedPlayer :   AVAudioPlayer?
    
    var currentPlayer : AVAudioPlayer?
    
    var audioPlayers : Array<AVAudioPlayer>?
    
    enum PanDirection {
        case Left
        case Right
    }
    
    var direction : PanDirection = PanDirection.Left
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Let's Hurt Tonight by OneRepublic
        
        let url = URL.init(fileURLWithPath: Bundle.main.path(forResource: "Let's Hurt Tonight", ofType: "m4a")!)
        
        do {
            try hurtPlayer = AVAudioPlayer(contentsOf: url)
            hurtPlayer?.delegate = self as AVAudioPlayerDelegate
            
            //hurtPlayer?.prepareToPlay()
            
        } catch let error as NSError {
            
            print("audioPlayer error \(error.localizedDescription)")
            
        }
        
        // Born by OneRepublic
    
        let bornURL = URL.init(fileURLWithPath: Bundle.main.path(forResource: "Born", ofType: "mp3")!)
        
        do {
            try bornPlayer = AVAudioPlayer(contentsOf: bornURL)
            bornPlayer?.delegate = self as AVAudioPlayerDelegate
            
        } catch let error as NSError {
            
            print("audioPlayer error \(error.localizedDescription)")
        }
        
        
        // Better by OneRepublic
        
        let betterURL = URL.init(fileURLWithPath: Bundle.main.path(forResource: "Better", ofType: "m4a")!)
        
        do {
            try betterPlayer = AVAudioPlayer(contentsOf: betterURL)
            betterPlayer?.delegate = self as AVAudioPlayerDelegate
            
        } catch let error as NSError {
            print ("audioPlayer error \(error.localizedDescription)")
        }
        
        // Human by OneRepublic
        
        let humanURL = URL.init(fileURLWithPath: Bundle.main.path(forResource: "Human", ofType: "m4a")!)
        
        do {
            try humanPlayer = AVAudioPlayer(contentsOf: humanURL)
            humanPlayer?.delegate = self as AVAudioPlayerDelegate
            
        } catch let error as NSError {
            print ("audioPlayer error \(error.localizedDescription)")
            
        }
        
        // 440Hz Tone
        
        let toneURL = URL.init(fileURLWithPath: Bundle.main.path(forResource: "440", ofType: "m4a")!)
        
        do {
            try tonePlayer = AVAudioPlayer(contentsOf: toneURL)
            tonePlayer?.delegate = self as AVAudioPlayerDelegate
        
        } catch let error as NSError {
            
            print("audioPlayer: \(error.localizedDescription)")
        }
        
        
        // If I Lose Myself by OneRepublic
        let loseURL = URL.init(fileURLWithPath: Bundle.main.path(forResource: "If I Lose Myself", ofType: "mp3")!)
        
        do {
            try losePlayer = AVAudioPlayer(contentsOf: loseURL)
            losePlayer?.delegate = self as AVAudioPlayerDelegate
        } catch let error as NSError {
            
            print ("audioPlayer error: \(error.localizedDescription)")
        }
        
        // Lift Me Up by OneRepublic
        
        let liftURL = URL.init(fileURLWithPath: Bundle.main.path(forResource: "Lift Me Up", ofType: "m4a")!)
        
        do {
            try liftPlayer = AVAudioPlayer(contentsOf: liftURL)
            losePlayer?.delegate = self as AVAudioPlayerDelegate
        } catch let error as NSError {
            
            print ("audioPlayer error: \(error.localizedDescription)")
        }
        
        // Heaven by OneRepublic
        
        let heavenURL = URL.init(fileURLWithPath: Bundle.main.path(forResource: "Heaven", ofType: "m4a")!)
        
        do {
            try heavenPlayer = AVAudioPlayer(contentsOf: heavenURL)
            heavenPlayer?.delegate = self as AVAudioPlayerDelegate
            
        } catch let error as NSError {
            print("audioError: \(error.localizedDescription)")
        }
       
        // I Lived by OneRepublic
        
        let livedURL = URL.init(fileURLWithPath: Bundle.main.path(forResource: "I Lived", ofType: "mp3")!)
        
        do {
            try livedPlayer = AVAudioPlayer(contentsOf: livedURL)
            livedPlayer?.delegate = self as AVAudioPlayerDelegate
        
        } catch let error as NSError {
            print("audioError: \(error.localizedDescription)")
        }
        
        
        if hurtPlayer != nil && betterPlayer != nil && bornPlayer != nil && humanPlayer != nil && losePlayer != nil && liftPlayer != nil && heavenPlayer != nil && tonePlayer != nil && livedPlayer != nil {
            
            audioPlayers = [hurtPlayer!, bornPlayer!, betterPlayer!, humanPlayer!, losePlayer!, liftPlayer!, heavenPlayer!, livedPlayer!, tonePlayer!, tonePlayer!]
            
        }
        
    
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            UIApplication.shared.beginReceivingRemoteControlEvents()
            
        } catch let error as NSError {
            print("error: \(error)")
        }
        
    
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func play(_ sender: Any) {
        
        
        if pickerView?.selectedRow(inComponent: 0) == 0 {
            
            if let player = hurtPlayer {
                player.play()
                currentPlayer = player
                
                if repeatSwitch?.isOn == true {
                    player.numberOfLoops = -1 //negative causes indefinite repeat
                }
            }
            
            startPan()
            if timer != nil { timer?.fire() }
        }
        
        if pickerView?.selectedRow(inComponent: 0) == 1 {
            
            if let player = bornPlayer {
                player.play()
                currentPlayer = player
                
                if repeatSwitch?.isOn == true {
                    player.numberOfLoops = -1 //negative causes indefinite repeat
                }
            }
            
            startPan()
            if timer != nil { timer?.fire() }
            
        }
        
        if pickerView?.selectedRow(inComponent: 0) == 2 {
            
            if let player = betterPlayer {
                player.play()
                currentPlayer = player
                
                if repeatSwitch?.isOn == true {
                    player.numberOfLoops = -1 //negative causes indefinite repeat
                }
            }
            
            startPan()
            if timer != nil { timer?.fire() }
        }
        
        
        if pickerView?.selectedRow(inComponent: 0) == 3 {
            
            if let player = humanPlayer {
                player.play()
                currentPlayer = player
                
                if repeatSwitch?.isOn == true {
                    player.numberOfLoops = -1 //negative causes indefinite repeat
                }
            }
            
            startPan()
            if timer != nil { timer?.fire() }
        }
        
        if pickerView?.selectedRow(inComponent: 0) == 4 {
            
            if let player = losePlayer {
                player.play()
                currentPlayer = player
                
                if repeatSwitch?.isOn == true {
                    player.numberOfLoops = -1 //negative causes indefinite repeat
                }
                
                startPan()
                if timer != nil { timer?.fire() }
            }
        }
        
        if pickerView?.selectedRow(inComponent: 0) == 5 {
           
            if let player = liftPlayer {
                player.play()
                currentPlayer = player
                
                if repeatSwitch?.isOn == true {
                    player.numberOfLoops = -1 //negative causes indefinite repeat
                }
                
                startPan()
                if timer != nil { timer?.fire() }
            }
        }
        
        if pickerView?.selectedRow(inComponent: 0) == 6 {
            
            if let player = heavenPlayer {
                player.play()
                currentPlayer = player
                
                if repeatSwitch?.isOn == true {
                    player.numberOfLoops = -1 //negative causes indefinite repeat
                }
                
                startPan()
                if timer != nil { timer?.fire() }
            }
        }
        
        if pickerView?.selectedRow(inComponent: 0) == 7 {
            
            if let player = livedPlayer {
                player.play()
                currentPlayer = player
                
                if repeatSwitch?.isOn == true {
                    player.numberOfLoops = -1
                }
                
                startPan()
                if timer != nil { timer?.fire() }
            }
        }
        
        if pickerView?.selectedRow(inComponent: 0) == 8 { //panning 440Hz
            
            if let player = tonePlayer {
                player.play()
                currentPlayer = player
                
                if repeatSwitch?.isOn == true {
                    player.numberOfLoops = -1
                }
                
                startPan()
                if timer != nil { timer?.fire() }
            }
        }
        
        if pickerView?.selectedRow(inComponent: 0) == 9 { //non-panning 440Hz
            
            if let player = tonePlayer {
                player.play()
                currentPlayer = player
                
                if repeatSwitch?.isOn == true {
                    player.numberOfLoops = -1
                }
                
                // startPan()
                // if timer != nil { timer?.fire() }
            }
        }
    }

    @IBAction func stop(_ sender: Any) {
        
        
        if let player = currentPlayer {
            player.stop()
        }
        
        if timer != nil {
            timer?.invalidate()
            
        }
        
        if textBox?.isEditing == true {
            self.textBox?.resignFirstResponder()
        }
        

    }
    
    
    @IBAction func rewind(_ sender: UILongPressGestureRecognizer) {
        
        if sender.state == .began {
            
            if let player = currentPlayer {
                player.stop()
                player.currentTime = 0
                
            }
            
            if timer != nil {
                timer?.invalidate()
            }
            
        }
        
    }
    
    
    func timerFireMethod(timer : Timer) {
        
        if direction == PanDirection.Left {
            
            if currentPlayer != nil {
                currentPlayer!.pan = 1.0
            }
            
            direction = .Right
            
        } else {
            
            if currentPlayer != nil {
                currentPlayer!.pan = -1.0
            }
            direction = .Left
        }
        
    }
    
    @IBAction func info(_ sender: Any) {
        
        // create UIAlertView to show std. osc. period for each song
        // Let's Hurt Tonight: 65bpm (subd.) -> 0.92 sec/osc
        // Born : 95bpm (subd.) -> 0.63 sec/osc OR 0.833 sec/osc
        // Lions : 96bpm (subd.) -> 0.625 sec/osc OR 0.833 sec/osc
        // Silence: 82bpm (subd.) -> 0.73 sec/osc
        // Love/Drugs: 128bpm -> 0.46875 sec/osc
        // I Lived: 120bpm -> 0.5 sec/osc
        
        /*
         Better .88
         Human  .43
         Lift   .52
         Heaven .63
        
        */
        let message = String.init(stringLiteral: "Let's Hurt Tonight: 65bpm 0.92 \n Born: 95bpm 0.63|0.83 \n Better: 0.88 \n Human: 0.43 \n Lift Me Up: 0.53 \n Heaven: 0.63 \n I Lived: 120bpm 0.5")
        
        let alert = UIAlertController(title: "Oscillations", message: message, preferredStyle: UIAlertControllerStyle.alert)
        let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
        
        alert.addAction(action)
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func startPan() {
        
        if textBox?.text != nil {
            
            let newStr : NSString = textBox!.text! as NSString
            let interval = newStr.doubleValue
            
            if interval == 0 {
                // do not pan, stereo is intentional
                return
                
            }
            
            timer = nil
            
            timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(timerFireMethod(timer:)), userInfo: nil, repeats: true)
        }
        
    }
    

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 10
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        if row == 0 {
            return "Let's Hurt Tonight"
        } else if row == 1 {
            return "Born"
        } else if row == 2 {
            return "Better"
        } else if row == 3 {
            return "Human"
        } else if row == 4 {
            return "If I Lose Myself"
        } else if row == 5 {
            return "Lift Me Up"
        } else if row == 6 {
            return "Heaven"
        } else if row == 7 {
            return "I Lived"
        } else if row == 8 {
            return "440 Hz Tone"
        } else if row == 9 {
            return "440 Hz Tone NP"
        }
        
        return ""
        
        
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        // change player to new URL
        
        for number in [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] {
            
            if row == number && audioPlayers != nil {
                audioPlayers![number].prepareToPlay()
            }
        }
        
        if (self.textBox?.isFirstResponder)! { self.textBox?.resignFirstResponder() }
        
        
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        
        return true
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully
        flag: Bool) {
        
        if timer != nil {
            timer?.invalidate()
            
        }
    }

}

