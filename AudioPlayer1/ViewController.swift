//
//  ViewController.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 11/3/16.
//  Copyright © 2016-2017 Hunter Eisler. All rights reserved.
//  Unauthorized copying of this file via any medium is strictly prohibited.
//  *Proprietary and confidential*

// **Potentials**
// !:3 sections in table view: Music; Tones; Instrumental
// !:annotate code so I don't have to comb through this shit like I always do to find what I want
// !:support multiple rhythms
// ?:Implement document handling thru iTunes/'Open In...' (can add audio w/o programmatic)

import UIKit
import AVFoundation

typealias TrackArray = Array<Dictionary<String, String>>

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AudioManagerDelegate {
    
    private var audioManager : AudioManager?
    private var selectedCells : Array<Int> = []
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var repeatBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var shuffleBarButtonItem: UIBarButtonItem!
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        repeatBarButtonItem.tintColor = UIColor.blue
        shuffleBarButtonItem.tintColor = UIColor.blue
        
        var trackArr : TrackArray?
        if let plistURL = Bundle.main.url(forResource: "Tracks", withExtension: "plist") { //PLIST url
            
            if let plistData = NSData(contentsOf: plistURL) { //PLIST data
                let data = plistData as Data
                
                do { //PLIST serialization to Array<Dictionary<String,String>> (TrackArray)
                    trackArr = try PropertyListSerialization.propertyList(from: data, options:.mutableContainers, format:nil) as? TrackArray
                } catch {
                    print(error)
                }
            }
        }
     
        if (trackArr != nil) {
            audioManager = AudioManager(withArray: trackArr!)
        }
        
        do {
            UIApplication.shared.beginReceivingRemoteControlEvents()
            
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            
        } catch let error as NSError {
            print("error: \(error)")
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        repeatBarButtonItem.tintColor = UIColor.blue
        shuffleBarButtonItem.tintColor = UIColor.blue
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let manager = audioManager {
            return manager.trackCount
        }
        
        return 0
    }
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        guard let manager = audioManager else { return cell }
        
        cell.textLabel?.text = manager.title(forIndex: indexPath.row)
        
        if (selectedCells.contains(indexPath.row)) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        
    
        return cell
        
    }
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if (selectedCells.contains(indexPath.row)) {
            if let rIndex = selectedCells.index(of: indexPath.row) {
                selectedCells.remove(at: rIndex)
            }
        } else {
            selectedCells.append(indexPath.row)
        }
        
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
   
    
    @IBAction func handlePlayButton(_ sender: Any) {
        
        if let manager = audioManager {
            
            if (manager.isPlaying == false) {
                
                _ = manager.playback(queued: selectedCells)
                
            } else {
                manager.stopPlayback()
            }
        }
    }

    @IBAction func handleRepeatShuffle(_ sender: UIBarButtonItem) {
        
        if (sender == repeatBarButtonItem) {
            if (repeatBarButtonItem.tintColor == UIColor.blue) {
                repeatBarButtonItem.tintColor = UIColor.red
            } else {
                repeatBarButtonItem.tintColor = UIColor.blue
            }
        }
        
        if (sender == shuffleBarButtonItem) {
            if (shuffleBarButtonItem.tintColor == UIColor.blue) {
                shuffleBarButtonItem.tintColor = UIColor.red
            } else {
                shuffleBarButtonItem.tintColor = UIColor.blue
            }
        }
    }
    
    func audioManagerDidCompletePlaylist() {
        
        
        if (repeatBarButtonItem.tintColor == UIColor.blue) {
            if let manager = audioManager {
                _ = manager.playback(queued: selectedCells)
            }
            
        else if (repeatBarButtonItem.tintColor == UIColor.red) {
                
                if let manager = audioManager {
                    manager.stopPlayback()
                }
            }
        }
    }
    
    func audioManagerPlaybackInterrupted() {
        
    }
    
    required init?(coder aDecoder: NSCoder) {
    
        super.init(coder: aDecoder)
    }
}

