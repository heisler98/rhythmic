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
// Implement 'sessions'

import UIKit
import AVFoundation
import MediaPlayer

typealias TrackArray = Array<Dictionary<String, String>>

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AudioManagerDelegate {
    
    private var audioManager : AudioManager?
    private var selectedCells : Array<Int> = []
    private var rhythmType : Rhythmic = .Crosspan
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var repeatBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var panTypeBarButtonItem: UIBarButtonItem!
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
            audioManager?.delegate = self as AudioManagerDelegate
        }
        
        do {
            UIApplication.shared.beginReceivingRemoteControlEvents()
            
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            let commandCenter = MPRemoteCommandCenter.shared()
            commandCenter.playCommand.addTarget(handler: { (event) -> MPRemoteCommandHandlerStatus in
                
                if let manager = self.audioManager {
                    manager.togglePauseResume()
                }
                
                return .success
                
            })
            
            commandCenter.pauseCommand.addTarget(handler: { (event) -> MPRemoteCommandHandlerStatus in
                
                if let manager = self.audioManager {
                    manager.togglePauseResume()
                }
                
                return .success
            })
            
            
            
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
                
                manager.rhythm = rhythmType
                _ = manager.playback(queued: selectedCells)
                
            } else {
                manager.stopPlayback()
            }
        }
    }

    @IBAction func handleRepeatShuffle(_ sender: UIBarButtonItem) {
        
        if (sender == repeatBarButtonItem) {
            if (repeatBarButtonItem.title == "Repeat") {
                repeatBarButtonItem.title = "One-time"
            } else if (repeatBarButtonItem.title == "One-time") {
                repeatBarButtonItem.title = "Repeat"
            }
            
            
        }
        
        if (sender == panTypeBarButtonItem) {
            
            switch panTypeBarButtonItem.title! {
                
            case "Crosspan":
                panTypeBarButtonItem.title = "Bilateral"
                rhythmType = .Bilateral
                break
                
            case "Bilateral":
                panTypeBarButtonItem.title = "Synthesis"
                rhythmType = .Synthesis
                break
                
            case "Synthesis":
                panTypeBarButtonItem.title = "Crosspan"
                rhythmType = .Crosspan
                break
                
            default:
                break
            }
        }
        
    }
    
    func audioManagerDidCompletePlaylist() { //<<implement repeat
        
        if (repeatBarButtonItem.title == "One-time") {
            selectedCells = []
            self.tableView.reloadData()
        } else if (repeatBarButtonItem.title == "Repeat") {
            
            if let manager = audioManager {
                _ = manager.playback(queued: selectedCells)
            }
            
        }
    }
    
    func audioManagerPlaybackInterrupted() {
        
    }
    
    required init?(coder aDecoder: NSCoder) {
    
        super.init(coder: aDecoder)
    }
}

