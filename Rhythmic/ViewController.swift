//
//  ViewController.swift
//  Rhythmic
//
//  Created by Hunter Eisler on 6/12/18.
//  Copyright © 2018 Hunter Eisler. All rights reserved.
//

import Cocoa
import AVFoundation

class ViewController: NSViewController {
    
    var timer : RepeatingTimer?
    
    @IBOutlet weak var slider: NSSlider!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func buttonPushed(_ sender: Any) {
        
        guard let url = Bundle.main.url(forResource: "boum", withExtension: "m4a") else { return }
        let player : AVAudioPlayer
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player.pan = 1

        } catch {
            print(error)
            return
        }
        
        timer = RepeatingTimer(timeInterval: slider.doubleValue)
        timer!.eventHandler = {
            player.currentTime = 0
            player.pan *= -1
            player.play()
        }
        
        timer!.resume()
        
    }
    
    @IBAction func stop(_ sender: Any) {
        timer!.suspend()
    }
}


