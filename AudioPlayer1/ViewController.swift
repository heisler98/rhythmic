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
// make JSOn & copy into documents upon first start to always ensure a file

import UIKit
import AVFoundation
import MediaPlayer
import os.log

typealias TrackArray = Array<Track>

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AudioManagerDelegate {
    
    //MARK: - Private property controls
    private var audioManager : AudioManager?
    private var selectedCells : Array<Int> = []
    
    // MARK: - IBOutlets
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var toolbar: UIToolbar!
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
        //create new manager from preset mp3s in bundle
        
        audioManager = AudioManager()
        audioManager?.delegate = self as AudioManagerDelegate
        
        if let theTracks = AudioManager.loadTracks() {
            do { try audioManager?.setTracks(theTracks) }
            catch let error {
                print("\(error)")
            }
        }
        
        if let theSessions = AudioManager.loadSessions() {
            do { try audioManager?.setSessions(theSessions) }
            catch let error {
                print("\(error)")
            }
        }
        
        self.navBar.prefersLargeTitles = true
        
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
                
                manager.skipCurrentTrack()
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
    
    // MARK: - Audio Manager controls
    
    func newTrack(at url: URL) -> Bool {
        
        //getting name+period:
        //option 1 - uialertview (+ bpmanalyzer)
        //option 2 - modal view controller + bpmanalyzer
        
        let lastComponent = url.pathComponents.last!
        let firstDot = lastComponent.index(of: ".") ?? lastComponent.endIndex
        let fileName = lastComponent[..<firstDot]
        
        let alert = UIAlertController(title: "Period", message: "Enter the desired period for the piece.", preferredStyle: .alert)
        alert.addTextField(configurationHandler: nil)
        
        let action = UIAlertAction(title: "Done", style: .default, handler: {(alertAction) -> Void in
            
            if let period = alert.textFields?.first?.text {
            let category = "song"
            
                let newTrack = Track(title: String(fileName), period: Double(period)!, category: category, fileName: lastComponent, rhythm: .Bilateral, rate: .Normal)
            
            if let manager = self.audioManager {
                manager.add(newTrack: newTrack)
                self.tableView.reloadData()
                
            }
            }})
        
        alert.addAction(action)
        self.present(alert, animated: true, completion: {() -> Void in })
        
        return true
    }
    
    // MARK: - Table View data source controls
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard let manager = self.audioManager else { return 0 }
        
        if section == 0 {
            return manager.sessionCount
        }
        return manager.trackCount
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Sessions"
        } else {
            return "Tracks"
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        if indexPath.section == 0 {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "sessionCell", for: indexPath)
            guard let manager = audioManager else { return cell }
            
            cell.textLabel?.text = manager.sessionInformation(forIndex: indexPath.row).0
            cell.detailTextLabel?.text = String(manager.sessionInformation(forIndex: indexPath.row).1) + " tracks"
            
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        guard let manager = audioManager else { return cell }
        
        cell.textLabel?.text = manager.title(forIndex: indexPath.row)
        cell.detailTextLabel?.text = manager.rhythmRate(forIndex: indexPath.row)
        
        if (selectedCells.contains(indexPath.row)) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }

        return cell
        
    }
    
    // MARK: - Table View delegate controls
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if (indexPath.section == 0) {
            
            if audioManager?.isPlayingSession == true {
                self.audioManager?.stopPlayback()
                tableView.deselectRow(at: indexPath, animated: true)
                return
            }
            self.audioManager?.playSession(atIndex: indexPath.row)
            return
        }
        
        let cell = tableView.cellForRow(at: indexPath)
        
        if (selectedCells.contains(indexPath.row)) {
            if let rIndex = selectedCells.index(of: indexPath.row) {
                selectedCells.remove(at: rIndex)
            }
            cell?.accessoryType = .none
        } else {
            selectedCells.append(indexPath.row)
            cell?.accessoryType = .checkmark
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
   
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        return true
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        
        if indexPath.section == 0 {
            return .delete
        }
        
        return .none
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if (editingStyle == .delete && indexPath.section == 0) {
            self.tableView.beginUpdates()
            self.audioManager?.deleteSession(atIndex: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            self.tableView.endUpdates()
            
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        if indexPath.section == 1 {
        
            let bilateral = UIContextualAction(style: .normal, title: "Bilateral", handler: { action, view, completionHandler in
                
                self.audioManager?.setRhythm(Rhythmic.Bilateral, forIndex:indexPath.row)
                completionHandler(true)
                //self.tableView.reloadRows(at: [indexPath], with: .none)
                let cell = tableView.cellForRow(at: indexPath)
                cell?.detailTextLabel?.text = self.audioManager?.rhythmRate(forIndex: indexPath.row)
                if cell?.accessoryType != .checkmark {
                    cell?.accessoryType = .checkmark
                    self.selectedCells.append(indexPath.row)
                }
            })
            bilateral.backgroundColor = UIColor.red
            
            let crosspan = UIContextualAction(style: .normal, title: "Crosspan", handler: { action, view, completionHandler in
                
                self.audioManager?.setRhythm(Rhythmic.Crosspan, forIndex:indexPath.row)
                completionHandler(true)
                let cell = tableView.cellForRow(at: indexPath)
                cell?.detailTextLabel?.text = self.audioManager?.rhythmRate(forIndex: indexPath.row)
                if cell?.accessoryType != .checkmark {
                    cell?.accessoryType = .checkmark
                    self.selectedCells.append(indexPath.row)
                }
            })
            crosspan.backgroundColor = UIColor.purple
            
            let synthesis = UIContextualAction(style: .normal, title: "Synthesis", handler: { action, view, completionHandler in
                
                self.audioManager?.setRhythm(Rhythmic.Synthesis, forIndex:indexPath.row)
                completionHandler(true)
                let cell = tableView.cellForRow(at: indexPath)
                cell?.detailTextLabel?.text = self.audioManager?.rhythmRate(forIndex: indexPath.row)
                if cell?.accessoryType != .checkmark {
                    cell?.accessoryType = .checkmark
                    self.selectedCells.append(indexPath.row)
                }
            })
            synthesis.backgroundColor = UIColor.blue
            
            let stitch = UIContextualAction(style: .normal, title: "Stitch", handler: { action, view, completionHandler in
                
                self.audioManager?.setRhythm(Rhythmic.Stitch, forIndex:indexPath.row)
                completionHandler(true)
                let cell = tableView.cellForRow(at: indexPath)
                cell?.detailTextLabel?.text = self.audioManager?.rhythmRate(forIndex: indexPath.row)
                if cell?.accessoryType != .checkmark {
                    cell?.accessoryType = .checkmark
                    self.selectedCells.append(indexPath.row)
                }
            })
            stitch.backgroundColor = UIColor.gray
            
            let config = UISwipeActionsConfiguration(actions: [bilateral, synthesis, crosspan, stitch])
            config.performsFirstActionWithFullSwipe = false
            return config
    }
        return nil
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        if indexPath.section == 1 {
        
            let half = UIContextualAction(style: .normal, title: "0.5x", handler: { action, view, completionHandler in
                
                self.audioManager?.setRate(PanRate.Half, forIndex: indexPath.row)
                completionHandler(true)
                let cell = tableView.cellForRow(at: indexPath)
                cell?.detailTextLabel?.text = self.audioManager?.rhythmRate(forIndex: indexPath.row)
                if cell?.accessoryType != .checkmark {
                    cell?.accessoryType = .checkmark
                    self.selectedCells.append(indexPath.row)
                }
            })
            half.backgroundColor = UIColor.red
            
            let normal = UIContextualAction(style: .normal, title: "1x", handler: { action, view, completionHandler in
                
                self.audioManager?.setRate(PanRate.Normal, forIndex: indexPath.row)
                completionHandler(true)
                let cell = tableView.cellForRow(at: indexPath)
                cell?.detailTextLabel?.text = self.audioManager?.rhythmRate(forIndex: indexPath.row)
                if cell?.accessoryType != .checkmark {
                    cell?.accessoryType = .checkmark
                    self.selectedCells.append(indexPath.row)
                }
            })
            normal.backgroundColor = UIColor.gray
            
            let double = UIContextualAction(style: .normal, title: "2x", handler: { action, view, completionHandler in
                
                self.audioManager?.setRate(PanRate.Double, forIndex: indexPath.row)
                completionHandler(true)
                let cell = tableView.cellForRow(at: indexPath)
                cell?.detailTextLabel?.text = self.audioManager?.rhythmRate(forIndex: indexPath.row)
                if cell?.accessoryType != .checkmark {
                    cell?.accessoryType = .checkmark
                    self.selectedCells.append(indexPath.row)
                }
            })
            double.backgroundColor = UIColor.blue
            
            let quad = UIContextualAction(style: .normal, title: "4x", handler: { action, view, completionHandler in
                
                self.audioManager?.setRate(PanRate.Quad, forIndex: indexPath.row)
                completionHandler(true)
                let cell = tableView.cellForRow(at: indexPath)
                cell?.detailTextLabel?.text = self.audioManager?.rhythmRate(forIndex: indexPath.row)
                if cell?.accessoryType != .checkmark {
                    cell?.accessoryType = .checkmark
                    self.selectedCells.append(indexPath.row)
                }
            })
            quad.backgroundColor = UIColor.purple
            
            let config = UISwipeActionsConfiguration(actions: [half, normal, double, quad])
            config.performsFirstActionWithFullSwipe = false
            return config
    }
        return nil
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    // MARK: - UI Controls
    @IBAction func handlePlayButton(_ sender: Any) {
        
        if let manager = audioManager {
            
            if (selectedCells.isEmpty == true) {
                if (manager.isPlaying == true) {
                    manager.stopPlayback()
                
                }
                return
            }
            
            if (manager.isPlaying == false) {
                
                _ = manager.playback(queued: selectedCells)
                
            } else {
                manager.stopPlayback()
            }
        }
    }
    
    @IBAction func newSession(_ sender: Any) {
        
        if selectedCells.isEmpty == true {
            
            let alert = UIAlertController(title: "Select Tracks", message: "To create a new session, select some tracks to add.", preferredStyle: .alert)
            let action = UIAlertAction(title: "Got it", style: .default, handler: nil)
            alert.addAction(action)
            
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        let alert = UIAlertController(title: "New Session", message: "Provide a name for the new session.", preferredStyle: .alert)
        alert.addTextField(configurationHandler: { (textField) -> Void in
            
            textField.placeholder = "Session 1"
        })
        
        let doneAction = UIAlertAction(title: "Done", style: .default, handler: { (alertAction) -> Void in
            
            guard let name = alert.textFields?.first?.text else { return }
            self.audioManager?.createSession(self.selectedCells, named: name)
            self.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
            
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(cancelAction)
        alert.addAction(doneAction)
        
        self.present(alert, animated: true, completion: { () -> Void in })
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
    func audioManagerDidCompletePlaylist() { 
       audioManager?.repeatQueue()
    }
    
    func audioManagerPlaybackInterrupted() {
        
    }
    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
    
        
        super.init(coder: aDecoder)
    }
}

