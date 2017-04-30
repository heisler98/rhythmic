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
    
    var hurtPlayer : AVAudioPlayer?
    var bornPlayer : AVAudioPlayer?
    var lionsPlayer : AVAudioPlayer?
    var silencePlayer : AVAudioPlayer?
    var losePlayer : AVAudioPlayer?
    var tonePlayer : AVAudioPlayer?
    var lovePlayer : AVAudioPlayer?
    
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
        
        
        // Lions by Skillet
        
        let lionsURL = URL.init(fileURLWithPath: Bundle.main.path(forResource: "Lions", ofType: "mp3")!)
        
        do {
            try lionsPlayer = AVAudioPlayer(contentsOf: lionsURL)
            lionsPlayer?.delegate = self as AVAudioPlayerDelegate
            
        } catch let error as NSError {
            print ("audioPlayer error \(error.localizedDescription)")
        }
        
        // The Sound of Silence by Disturbed
        
        let silenceURL = URL.init(fileURLWithPath: Bundle.main.path(forResource: "The Sound of Silence", ofType: "m4a")!)
        
        do {
            try silencePlayer = AVAudioPlayer(contentsOf: silenceURL)
            silencePlayer?.delegate = self as AVAudioPlayerDelegate
            
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
        
        //Love/Drugs by Strange Familia
        
        let loveURL = URL.init(fileURLWithPath: Bundle.main.path(forResource: "LoveDrugs", ofType: "mp3")!)
        
        do {
            try lovePlayer = AVAudioPlayer(contentsOf: loveURL)
            losePlayer?.delegate = self as AVAudioPlayerDelegate
        } catch let error as NSError {
            
            print ("audioPlayer error: \(error.localizedDescription)")
        }
        
        if hurtPlayer != nil && lionsPlayer != nil && bornPlayer != nil && silencePlayer != nil && losePlayer != nil && lovePlayer != nil && tonePlayer != nil {
            
            audioPlayers = [hurtPlayer!, bornPlayer!, lionsPlayer!, silencePlayer!, losePlayer!, lovePlayer!, tonePlayer!, tonePlayer!]
            
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
            
            if let player = lionsPlayer {
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
            
            if let player = silencePlayer {
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
           
            if let player = lovePlayer {
                player.play()
                currentPlayer = player
                
                if repeatSwitch?.isOn == true {
                    player.numberOfLoops = -1 //negative causes indefinite repeat
                }
                
                startPan()
                if timer != nil { timer?.fire() }
            }
        }
        
        if pickerView?.selectedRow(inComponent: 0) == 6 { // panning 440hz
            
            if let player = tonePlayer {
                player.play()
                currentPlayer = player
                
                if repeatSwitch?.isOn == true {
                    player.numberOfLoops = -1 //negative causes indefinite repeat
                }
                
                startPan()
                if timer != nil { timer?.fire() }
            }
        }
        
        
        
        if pickerView?.selectedRow(inComponent: 0) == 7 { //non-panning 440Hz
            
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
        let message = String.init(stringLiteral: "Let's Hurt Tonight: 65bpm 0.92 \n Born: 95bpm 0.63|0.83 \n Lions: 96bpm 0.625|0.83 \n The Sound of Silence: 82bpm 0.73 \n Love/Drugs: 128bpm 0.47")
        
        let alert = UIAlertController(title: "Oscillations", message: message, preferredStyle: UIAlertControllerStyle.alert)
        let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
        
        alert.addAction(action)
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func startPan() {
        
        if textBox?.text != nil {
            
            let newStr : NSString = textBox!.text! as NSString
            let interval = newStr.doubleValue
            
            timer = nil
            
            timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(timerFireMethod(timer:)), userInfo: nil, repeats: true)
        }
        
    }
    

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 8
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        if row == 0 {
            return "Let's Hurt Tonight"
        } else if row == 1 {
            return "Born"
        } else if row == 2 {
            return "Lions"
        } else if row == 3 {
            return "The Sound of Silence"
        } else if row == 4 {
            return "If I Lose Myself"
        } else if row == 5 {
            return "Love/Drugs"
        } else if row == 6 {
            return "440 Hz Tone"
        } else if row == 7 {
            return "440 Hz Tone NP"
        }
        
        return ""
        
        
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        // change player to new URL
        
        for number in [0, 1, 2, 3, 4, 5, 6, 7] {
            
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

