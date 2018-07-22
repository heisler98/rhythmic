//
//  EntrainViewController.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 7/6/18.
//  Copyright © 2018 Hunter Eisler. All rights reserved.
//

import UIKit

class EntrainViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var fields: [UITextField]!
    @IBOutlet weak var segmentedControl : UISegmentedControl!
    
    let entrainer = Entrainment()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tabBarItem = UITabBarItem(title: "Entrainer", image: nil, tag: 1)
    }
    
    @IBAction func segmentSelected(_ sender : UISegmentedControl) {
        
        entrainer.stopAudio()
        
        guard let text = fields[0].text else { return }
        guard let freq = Double(text) else { return }
        let frequency = NSNumber(value: freq)
        
        switch sender.selectedSegmentIndex {
        
        case 0: //bilateral
            guard let periodTxt = fields[1].text else { return }
            guard let period = Double(periodTxt) else { return }
            entrainer.bilateral(tonalFrequency: frequency, period: NSNumber(value: period))
            break
            
        case 1: //binaural
            entrainer.binaural(midFrequency: frequency)
            break
            
        case 2: //isochronic
            guard let targetTxt = fields[2].text else { return }
            guard let target = Double(targetTxt) else { return }
            entrainer.isochronic(tonalFrequency: frequency, brainwaveTarget: NSNumber(value: target))
            break
            
        default:
            break
        }
        
    }
    
    @IBAction func fieldResignsResponder(_ sender : Any) {
        _ = fields.map { (textField) -> Void in
            textField.resignFirstResponder()
        }
    }

  
}
