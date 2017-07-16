//
//  ViewController.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 11/3/16.
//  Copyright © 2016 Hunter Eisler. All rights reserved.
//


import UIKit
import AVFoundation

struct Track {
    var fileName : String
    var fileExtension : String
    
    var bundlePath : String? {
        if let path = Bundle.main.path(forResource: fileName, ofType: fileExtension) {
            return path
        }
        return nil
    }
    
    var bundleURL : URL? {
        if let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) {
            return url
        }
        return nil
    }
    
    
}

struct TrackManager {
    
    var tracks : Array<Track>?
    
    func musicFileDictionary() -> MusicFileDictionary {
        
        if (tracks != nil) {
            
            var titles : Array<String> = []
            var urls : Array<URL> = []
            
            
            for aTrack in tracks! {
                
                if let aURL = aTrack.bundleURL {
                    
                    urls.append(aURL)
                    titles.append(aTrack.fileName)
                    
                } else {
                    print("Skipped building track due to missing file; check name and extension")
                }
                
            }
            
            return [titles : urls]
        }
        
        return [:] // [Array<String> : Array<URL>]
    }
    
    
    
    
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    private var defaultManager : AudioManager?
    private var allTracks : TrackManager?
    private var selectedTracks : TrackManager?
    private var periods : Array<Double>?
    private let headerView : UITableViewHeaderFooterView!
    private var selectedRows : Array<IndexPath> = []
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var button: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let titles = ["Let's Hurt Tonight", "Born", "Better", "Human", "If I Lose Myself", "Lift Me Up", "Heaven", "I Lived", "Start Over", "Marchin On", "Counting Stars", "Hand of God"]
        
        let m4a = "m4a"
        let mp3 = "mp3"
        
        let extensions = [m4a, mp3, m4a, m4a, mp3, m4a, m4a, mp3, mp3, m4a, m4a, m4a]
        
        var tracks : Array<Track> = []
        periods = []
        
        for number in 0...(titles.count-1) {
            
            let aTrack = Track(fileName: titles[number], fileExtension: extensions[number])
            
            tracks.append(aTrack)
            
            
        }
        
        
        
        allTracks = TrackManager(tracks: tracks)
        selectedTracks = TrackManager(tracks: [])
        /*
         do {
         defaultManager = try AudioManager(withDictionary: allTracks!.musicFileDictionary(), repeating: true, panTimes: periods)
         } catch let error as NSError {
         print("AudioManager initialization error: \(error)")
         }
         */
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            UIApplication.shared.beginReceivingRemoteControlEvents()
            
            NotificationCenter.default.addObserver(self, selector: #selector(ViewController.audioSessionInterrupted), name: NSNotification.Name.AVAudioSessionInterruption, object: self)
            
            
            
        } catch let error as NSError {
            print("error: \(error)")
        }
        
        
        
        
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        headerView.textLabel?.text = "Rhythmic"
        headerView.textLabel?.textAlignment = .center
        tableView.tableHeaderView = headerView
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        
        if (defaultManager != nil) {
            defaultManager!.stop(andReset: false)
        }
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
            
        case 10:
            return 0.555 //Counting Stars
            
        case 11:
            return 0.78 //Hand of God
            
        default:
            return 0.0
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if (allTracks != nil) {
            return allTracks!.tracks!.count
        }
        
        return 11
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.textLabel?.text = allTracks?.tracks?[indexPath.row].fileName
        
        if (selectedRows.contains(indexPath) == true) {
            cell.accessoryType = .checkmark
        }
        else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    
     
     func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if (selectedRows.contains(indexPath)) { //selection doesn't hold on reloadRows:at:with:
            if let index = selectedRows.index(of: indexPath) {
                selectedRows.remove(at: index)
                tableView.reloadRows(at: [indexPath], with: .none)
                return
            }
        }
        
        selectedRows.append(indexPath)
        tableView.reloadRows(at: [indexPath], with: .none)
     }
     
     func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        if let index = selectedRows.index(of: indexPath) {
            selectedRows.remove(at: index)
            tableView.reloadRows(at: [indexPath], with: .none)
            return
        }
        
        selectedRows.append(indexPath)
        tableView.reloadRows(at: [indexPath], with: .none)
     
     }
     
 
    @IBAction func activateButton(_ sender: Any) {
        
        let button = sender as! UIButton
        
        
            if (button.isSelected == false) {
                
                    for indexPath in self.selectedRows {
                        
                        if let trackToAdd = allTracks?.tracks?[indexPath.row] {
                            self.selectedTracks?.tracks?.append(trackToAdd)
                            self.periods?.append(self.period(forIndex: indexPath.row))
                        }
                    }
                
                
                    do {
                        defaultManager = nil
                        defaultManager = try AudioManager(withDictionary: (selectedTracks?.musicFileDictionary())!, repeating: true, panTimes: periods!)
                        
                        _ = defaultManager?.beginPlayback()
                    } catch let error as NSError {
                        print("\(error)")
                    }
                    
                
                button.isSelected = true
                
                } else { // if button.isSelected == true
                
                if (defaultManager != nil) {
                    defaultManager?.stop(andReset: true)
                    selectedTracks?.tracks = []
                    self.periods = []
                }
                
                
                
                button.isSelected = false
            }
            
        }

    
    @IBAction func handleGesture() {
        
        if (defaultManager != nil) {
            
            if (defaultManager!.isPlaying == true) {
                defaultManager!.pause()
                button.titleLabel?.text = "Hold to resume"
            } else {
                button.titleLabel?.text = "Stop"
                _  = defaultManager!.resumePlayback()
            }
        }
    }

    
    required init?(coder aDecoder: NSCoder) {
        
        headerView = UITableViewHeaderFooterView()
    
        super.init(coder: aDecoder)
        
        
    }
}

