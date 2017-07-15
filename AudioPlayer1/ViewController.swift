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
    private var selectedRows : Array<Int> = []
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let titles = ["Let's Hurt Tonight", "Born", "Better", "Human", "If I Lose Myself", "Lift Me Up", "Heaven", "I Lived", "Start Over", "Marchin On"]
        
        let m4a = "m4a"
        let mp3 = "mp3"
        
        let extensions = [m4a, mp3, m4a, m4a, mp3, m4a, m4a, mp3, mp3, m4a]
        
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.textLabel?.text = allTracks?.tracks?[indexPath.row].fileName
        
        
        return cell
    }
    
    /*

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        selectedRows.append(indexPath.row)
        self.periods?.append(self.period(forIndex: indexPath.row))
        
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        if let anIndex = selectedRows.index(of: indexPath.row) {
            selectedRows.remove(at: anIndex)

        }
        
        if let anotherIndex = periods?.index(of: self.period(forIndex: indexPath.row)) {
            periods?.remove(at: anotherIndex)
        }
        
        
    }
 
 */
    @IBAction func activateButton(_ sender: Any) {
        
        let button = sender as! UIButton
        
        if let selectedRows = self.tableView.indexPathsForSelectedRows {
            
            for indexPath in selectedRows {
                
                if let trackToAdd = allTracks?.tracks?[indexPath.row] {
                    self.selectedTracks?.tracks?.append(trackToAdd)
                    self.periods?.append(self.period(forIndex: indexPath.row))
                }
            }
        }
        
        if (button.isSelected == false) {
        
        do {
            defaultManager = try AudioManager(withDictionary: (selectedTracks?.musicFileDictionary())!, repeating: true, panTimes: periods!)
            
            _ = defaultManager?.beginPlayback()
        } catch let error as NSError {
            print("\(error)")
        }
        
        
        button.isSelected = true
        
        } else {
            
            if (defaultManager != nil) {
                defaultManager?.stop(andReset: true)
            }
            
            button.isSelected = false
        }
        
    }

}

