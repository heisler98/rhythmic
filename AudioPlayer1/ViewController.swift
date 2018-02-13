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
// Ability to change period of timer
// we'll need to go faster...

import UIKit
import AVFoundation
import MediaPlayer
import os.log

typealias TrackArray = Array<Dictionary<String, String>>

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AudioManagerDelegate {
    
    //MARK: - Private property controls
    private var audioManager : AudioManager?
    private var selectedCells : Array<Int> = []
    private var rhythmType : Rhythmic = .Crosspan
    
    // MARK: - IBOutlets
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var repeatBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var panTypeBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var panRateBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var pauseBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var playBarButtonItem: UIBarButtonItem!
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - View controls
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // load encoded audioManager instantiation
        // change as necessary inside with newTrackat:
        // be sure to either save or delegate out save upon finish
        
        
        if (loadAudioManager() == nil) {
            
            //create new manager from preset mp3s in bundle
            
            var trackArr : TrackArray?
            if let assetsDir = Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: nil) {
                
                
                if let plistURL = Bundle.main.url(forResource: "Tracks", withExtension: "plist") { //PLIST url
                    
                    if let plistData = NSData(contentsOf: plistURL) { //PLIST data
                        let data = plistData as Data
                        
                        do { //PLIST serialization to Array<Dictionary<String,String>> (TrackArray)
                            trackArr = try PropertyListSerialization.propertyList(from: data, options:.mutableContainers, format:nil) as? TrackArray
                        } catch {
                            print(error)
                            
                        }
                    }
                } //trackArr contains name, period, category...add path
                
                let background = DispatchQueue.global()
                
                background.sync {
                    
                    for asset in assetsDir {
                        
                        let destUrl = AudioManager.documentsDirectory.appendingPathComponent(asset.lastPathComponent)
                        
                        do {
                            try FileManager.default.copyItem(at: asset, to: destUrl)
                        } catch let error as NSError {
                            print("\(error)")
                        }
                    }
                    
                }
                
                if let arr = trackArr {
                    audioManager = AudioManager(withArray: arr)
                    audioManager?.delegate = self as AudioManagerDelegate
                    if let manager = audioManager { _ = saveAudioManager(manager: manager) }
                    
                }
            }
            
        }
        
        audioManager = loadAudioManager()
        audioManager?.delegate = self as AudioManagerDelegate
        if let manager = audioManager { _ = saveAudioManager(manager: manager) }
        
        
        
        do {
            UIApplication.shared.beginReceivingRemoteControlEvents()
            
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            let commandCenter = MPRemoteCommandCenter.shared()
            commandCenter.playCommand.addTarget(handler: { (event) -> MPRemoteCommandHandlerStatus in
                
                guard let manager = self.audioManager else { return .commandFailed }
                manager.togglePauseResume()
                return .success
                
            })
            
            commandCenter.pauseCommand.addTarget(handler: { (event) -> MPRemoteCommandHandlerStatus in
                
                guard let manager = self.audioManager else { return .commandFailed }
                manager.togglePauseResume()
                return .success
            })
            
            commandCenter.nextTrackCommand.addTarget(handler: {(event) -> MPRemoteCommandHandlerStatus in
                
                guard let manager = self.audioManager else { return .commandFailed }
                
                manager.stopPlayback() //counterintuitive, but should call audioPlayerDidFinishPlaying: & call up next track
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
        
        guard let manager = self.audioManager else { return }
        
        if (manager.isPlaying == true) {
            navBar.topItem?.setRightBarButton(pauseBarButtonItem, animated: false)
        } else {
            navBar.topItem?.setRightBarButton(playBarButtonItem, animated: false)
        }
    }
    
    // MARK: - Audio Manager controls
    
    private func loadAudioManager() -> AudioManager? {
        
        return NSKeyedUnarchiver.unarchiveObject(withFile: AudioManager.archiveURL.path) as? AudioManager
        
    }
    
    private func saveAudioManager(manager: AudioManager) -> Bool {
        
        return NSKeyedArchiver.archiveRootObject(manager, toFile: AudioManager.archiveURL.path)
    }
    
    func newTrack(at url: URL) -> Bool {
        
        //construct a TrackArray w/1 entry : Dict<String, String>
        //getting name+period:
        //option 1 - uialertview (+ bpmanalyzer)
        //option 2 - modal view controller + bpmanalyzer
        var trackArr = TrackArray()
        let lastComponent = url.pathComponents.last!
        let firstDot = lastComponent.index(of: ".") ?? lastComponent.endIndex
        let fileName = lastComponent[..<firstDot]
        
        let period = "0.5"
        let category = "song"
        
        trackArr.append(["title" : String(fileName), "period" : period, "category" : category, "extension" : url.pathExtension])
        
        //send to manager
        if let manager = self.audioManager {
            manager.add(newTrack: trackArr)
            self.tableView.reloadData()
            return self.saveAudioManager(manager: manager)
        }
        
        return true
    }
    
    // MARK: - Table View controls
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
   
    // MARK: - UI Controls
    @IBAction func handlePlayButton(_ sender: Any) {
        
        if let manager = audioManager {
            
            if (selectedCells.isEmpty == true) {
                if (manager.isPlaying == true) {
                    manager.stopPlayback()
                    navBar.topItem?.setRightBarButton(playBarButtonItem, animated: true)

                }
                return
            }
            
            if (manager.isPlaying == false) {
                
                manager.rhythm = rhythmType
                _ = manager.playback(queued: selectedCells)
                navBar.topItem?.setRightBarButton(pauseBarButtonItem, animated: true)
                
            } else {
                manager.stopPlayback()
                navBar.topItem?.setRightBarButton(playBarButtonItem, animated: true)
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
                panTypeBarButtonItem.title = "Stitch"
                rhythmType = .Stitch
                break
                
            case "Stitch":
                panTypeBarButtonItem.title = "Crosspan"
                rhythmType = .Crosspan
                break
                
            default:
                break
            }
        }
        
    }
    
    @IBAction func handlePanRateChange(_ sender: UIBarButtonItem) {
        
        guard let title = panRateBarButtonItem.title else { return }
        
        if let manager = self.audioManager {
        
        switch title {
            
        case "1x":
            panRateBarButtonItem.title = "2x"
            manager.rate = PanRate.Double
            break
            
        case "2x":
            panRateBarButtonItem.title = "4x"
            manager.rate = PanRate.Quad
            break
            
        case "4x":
            panRateBarButtonItem.title = "0.5x"
            manager.rate = PanRate.Half
            break
            
        case "0.5x":
            panRateBarButtonItem.title = "1x"
            manager.rate = PanRate.Normal
            break
            
        default:
            break
        }
    }
    }
    
    @IBAction func clearSelections(_ sender: Any) {
        
        selectedCells.removeAll(keepingCapacity: true)
        self.tableView.reloadData()
    }
    
    @IBAction func volumeChanged(_ sender: UISlider) {
        
        let newLevel = sender.value
        if let manager = self.audioManager {
            manager.updateVolume(newLevel)
        }
    }
    // MARK: - AudioManager delegate controls
    func audioManagerDidCompletePlaylist() { //<<implement repeat
        
        if (repeatBarButtonItem.title == "One-time") {
            selectedCells = []
            self.tableView.reloadData()
        } else if (repeatBarButtonItem.title == "Repeat") {
            audioManager?.repeatQueue()
        }
    }
    
    func audioManagerPlaybackInterrupted() {
        
    }
    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
    
        super.init(coder: aDecoder)
    }
}

