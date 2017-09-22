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

public class TableViewInputCell: UITableViewCell {
    
    @IBOutlet weak var textField: UITextField!
    
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AudioManagerDelegate {
    
    
    private var defaultManager : AudioManager?
    private var allTracks : TrackManager?
    private var selectedTracks : TrackManager?
    private var periods : Array<Double>?
    private var selectedRows : Array<IndexPath> = []
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var button: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let titles = ["Let's Hurt Tonight", "Born", "Better", "Human", "If I Lose Myself", "Lift Me Up", "Heaven", "I Lived", "Start Over", "Marchin On", "Counting Stars", "Hand of God", "What You Wanted", "Au Revoir", "Truth to Power", "Miracles", "Praying", "Praying by Kesha", "Preacher", "Song for Sienna", "Viva La Vida", "5 Secrets", "Learn to Let Go", "Looking too closely", "Looking too closely", "Collateral Beauty", "Life in Color", "Battle of the Heroes", "Beyond Main Theme", "Counting Star Instrumental", "Enterprising Young Men", "Feel Again Instrumental", "Jedi Steps and Finale", "Main Star Wars", "Star Trek Main Theme", "The Force Suite", "The Force Theme"]
        
        let m4a = "m4a"
        let mp3 = "mp3"
        
        let extensions = [m4a, mp3, m4a, m4a, mp3, m4a, m4a, mp3, mp3, m4a, m4a, m4a, m4a, m4a, m4a, m4a, m4a, m4a, m4a, mp3, mp3, m4a, m4a, m4a, m4a, mp3, m4a, mp3, mp3, mp3, mp3, mp3, mp3, mp3, mp3, mp3, mp3, mp3]
        
        var tracks : Array<Track> = []
        periods = []
        
        for number in 0...(titles.count-1) {
            
            let aTrack = Track(fileName: titles[number], fileExtension: extensions[number])
            
            tracks.append(aTrack)
            
            
        }
        
        
        
        allTracks = TrackManager(tracks: tracks)
        selectedTracks = TrackManager(tracks: [])
        
        do {
            UIApplication.shared.beginReceivingRemoteControlEvents()

            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            NotificationCenter.default.addObserver(self, selector: #selector(ViewController.audioSessionInterrupted), name: NSNotification.Name.AVAudioSessionInterruption, object: nil)
            
            
            
        } catch let error as NSError {
            print("error: \(error)")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func remoteControlReceived(with event: UIEvent?) {
        
        if event?.type == UIEventType.remoteControl {
            
            switch event!.subtype {
            case UIEventSubtype.remoteControlTogglePlayPause:
                if (defaultManager != nil) {
                    switch defaultManager!.isPlaying {
                    case true:
                        defaultManager!.pause()
                        break;
                    case false:
                        _ = defaultManager!.resumePlayback()
                    }
                }
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
            
        case 12:
            return 0.50 //What You Wanted
            
        case 13:
            return 0.51 //Au Revoir
            
        case 14:
            return 0.83 //Truth to Power
            
        case 15:
            return 0.62 //Miracles (Someone Special)
            
        case 16:
            return 0.81 //Praying
        case 17:
            return 0.81 //Praying
            
        case 18:
            return 0.857 //Preacher
            
        case 19:
            return 0.9756 //Song for Sienna
        
        case 20:
            return 0.87 //Viva La Vida
            
        case 21:
            return 1.15 //5 Secrets
        
        case 22:
            return 0.714 //Learn to Let Go
            
        case 23:
            return 0.3428 //Looking too closely
            
        case 24:
            return 0.6856 //Looking too closely
            
        case 25:
            return 0.461 //Collateral Beauty
            
        case 26:
            return 0.472 //Life in Color
            
        case 27:
            return 0.66 //Battle of the Heroes
            
        case 28:
            return 0.395 //Beyond Main Theme
            
        case 29:
            return 0.555 //Counting Stars - Instrumental
            
        case 30:
            return 0.405 //Enterprising Young Men
            
        case 31:
            return 0.429 //Feel Again - Instrumental
            
        case 32:
            return 0.594 //Jedi Steps and Finale
            
        case 33:
            return 0.698 //Star Wars (TFA) Main Theme
            
        case 34:
            return 0.405 //Star Trek Main Theme
            
        case 35:
            return 0.822 //The Force Suite
            
        case 36:
            return 0.681 //The Force Theme
            
        default:
            return 0.5
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if (section == 0) { //Music
            
            if (allTracks != nil) {
                return allTracks!.tracks!.count
            }
            
            return 37
        }
        
        if (section == 1) { //Tones
            return 0
        }
        
        if (section == 2) { //Instrumental
            return 0
        }
        
        return 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
        // Music; Tones; Instrumental
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if (indexPath.section == 0 || indexPath.section == 2) { //Music & Instrumental
            
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
        
        if (indexPath.section == 1) {   //Tones; requires manual input
            let cell = tableView.dequeueReusableCell(withIdentifier: "inputCell", for: indexPath)
            
            cell.textLabel?.text = allTracks?.tracks?[indexPath.row].fileName
            // may also need to set up & store textField period in Track structure or some such thing
            
            if (selectedRows.contains(indexPath) == true) {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if (selectedRows.contains(indexPath)) { //selection doesn't hold on reloadRows:at:with:
            if let index = selectedRows.index(of: indexPath) {
                selectedRows.remove(at: index)
                tableView.reloadRows(at: [indexPath], with: .automatic)
                return
            }
        }
        
        selectedRows.append(indexPath)
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        if let index = selectedRows.index(of: indexPath) {
            selectedRows.remove(at: index)
            tableView.reloadRows(at: [indexPath], with: .automatic)
            return
        }
        
        selectedRows.append(indexPath)
        tableView.reloadRows(at: [indexPath], with: .automatic)
        
    }
    
    
    @IBAction func activateButton(_ sender: Any) {
        
        let button = sender as! UIButton
        
        
        if (button.isSelected == false) {
            
            button.isSelected = true
            
            for indexPath in self.selectedRows {
                
                if let trackToAdd = allTracks?.tracks?[indexPath.row] {
                    self.selectedTracks?.tracks?.append(trackToAdd)
                    self.periods?.append(self.period(forIndex: indexPath.row))
                }
                
                if (selectedRows.count == 17) {
                    selectedRows.sort()
                    
                }
            }
            
            
            do {
                defaultManager = nil
                defaultManager = try AudioManager(withDictionary: (selectedTracks?.musicFileDictionary())!, repeating: true, panTimes: periods!)
                defaultManager?.delegate = self as AudioManagerDelegate
                
                _ = defaultManager?.beginPlayback()
            } catch let error as NSError {
                print("\(error)")
            }
            
            
        } else { // if button.isSelected == true
            button.isSelected = false
            if (defaultManager != nil) {
                defaultManager?.stop(andReset: true)
                selectedTracks?.tracks = []
                self.periods = []
            }
            
            
            
            
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
    
    func audioManagerDidCompletePlaylist() {
        
        button.isSelected = false
        self.activateButton(self.button)
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        
        
        super.init(coder: aDecoder)
        
        
    }
}

