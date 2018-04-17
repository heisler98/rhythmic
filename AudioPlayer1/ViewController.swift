//
//  ViewController.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 11/3/16.
//  Copyright © 2016-2017 Hunter Eisler. All rights reserved.
//  Unauthorized copying of this file via any medium is strictly prohibited.
//  *Proprietary and confidential*

// **Potentials**
// !: iTunes Music Library option attached
// !:support multiple rhythms
// Implement 'sessions'
// we'll need to go faster...slower...faster...slower...faster...
// ?: Collection view REM/stitch "sessions"/groups/categories/ - organized by speed etc

import UIKit
import AVFoundation
import MediaPlayer
import os.log
import AudioKit

typealias TrackArray = Array<Track>
let pi = 3.14159265


func absVal(_ param : Double) -> Double {
    if param < 0 {
        return -param
    }
    return param
}

func lemniscate(forTime t : Double, amplitude a : Double) -> (x : Double, y : Double) {
    let x = (a*cos(t)) / (1+(sin(t)*sin(t)))
    let y = (a*sin(t)*cos(t)) / (1+sin(t)*sin(t))
    return (x, y)
}

func council(forTime t: Double, radius r : Double) -> (x : Double, y : Double, z : Double) {
    let x = r*cos(t)
    let y = r*sin(t)
    let z = sin(2*r*t)
    
    return (x, y, z)
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AudioManagerDelegate {
    
    // MARK: - Private property controls
    private var audioManager : AudioManager?
    private var selectedCells : Array<Int> = []
    private var rhythmSession : Rhythm?
    private var stitchOn : Bool = false
    
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
        
        let alert = UIAlertController(title: "Period", message: "Enter the desired period or BPM for the piece '\(fileName)'.", preferredStyle: .alert)
        alert.addTextField(configurationHandler: nil)
        
        let action = UIAlertAction(title: "Done", style: .default, handler: {(alertAction) -> Void in
            
            if let period = alert.textFields?.first?.text {
            let category = "song"
                
                var doublePeriod : Double
                
                if Double(period)! < 10 {
                    doublePeriod = Double(period)!
                } else {
                    doublePeriod = 1/((Double(period)!)/60)
                
                }
            let newTrack = Track(title: String(fileName), period: doublePeriod, category: category, fileName: lastComponent, rhythm: .Bilateral, rate: .Normal)
            
                if let manager = self.audioManager {
                manager.add(newTrack: newTrack)
                self.tableView.reloadData()
                
            }
            }})
        //copyAction for track|file disparity – will not add new track to AM
        let copyAction = UIAlertAction(title: "Copy Only", style: .destructive, handler: nil)
        
        alert.addAction(action)
        alert.addAction(copyAction)
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
            cell.textLabel?.textColor = UIColor(red: 1, green: 0.4, blue: 0.4, alpha: 1.0)
        } else {
            cell.accessoryType = .none
            cell.textLabel?.textColor = UIColor.black
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
            cell?.textLabel?.textColor = UIColor.black
        } else {
            selectedCells.append(indexPath.row)
            cell?.accessoryType = .checkmark
            cell?.textLabel?.textColor = UIColor(red: 1, green: 0.4, blue: 0.4, alpha: 1.0)
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
                    cell?.textLabel?.textColor = UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0)
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
                    cell?.textLabel?.textColor = UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0)
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
                    cell?.textLabel?.textColor = UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0)
                    self.selectedCells.append(indexPath.row)
                }
            })
            synthesis.backgroundColor = UIColor.blue
            
            let stitch = UIContextualAction(style: .normal, title: "Swave", handler: { action, view, completionHandler in
                
                self.audioManager?.setRhythm(Rhythmic.Stitch, forIndex:indexPath.row)
                completionHandler(true)
                let cell = tableView.cellForRow(at: indexPath)
                cell?.detailTextLabel?.text = self.audioManager?.rhythmRate(forIndex: indexPath.row)
                if cell?.accessoryType != .checkmark {
                    cell?.accessoryType = .checkmark
                    cell?.textLabel?.textColor = UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0)
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
                    cell?.textLabel?.textColor = UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0)
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
                    cell?.textLabel?.textColor = UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0)
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
                    cell?.textLabel?.textColor = UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0)
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
                    cell?.textLabel?.textColor = UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0)
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
        
        if stitchOn == true {
            do {
                try AudioKit.stop()
                stitchOn = false
            } catch {
                print(error)
            }
            return
        }
        
        if let _ = rhythmSession {
            if rhythmSession!.isPlaying == true {
                _ = rhythmSession!.stop()
                return
            }
        }
        
        
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
    // MARK: - REM Rhythm controls
    @IBAction func initiateRhythm(_ sender : UIBarButtonItem) {
        //check for selections
        if selectedCells.isEmpty == true {
            return
        }
        
        //prompt for period
        let alert = UIAlertController(title: "Enter period", message: "Please enter the REM period.", preferredStyle: .alert)
        alert.addTextField(configurationHandler: {(textField) -> Void in
            textField.keyboardType = UIKeyboardType.decimalPad
            textField.keyboardAppearance = UIKeyboardAppearance.dark
            textField.placeholder = "0.50"
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let doneAction = UIAlertAction(title: "Done", style: .default, handler: { (alertAction) -> Void in
            if let secTxt = alert.textFields?.first?.text {
                if let sec = Double(secTxt) {
                    self.loadRhythm(withPeriod: sec, continuousSweeping: false)
                }
            }
            
        })
        let contAction = UIAlertAction(title: "Infinite", style: .default, handler: { (alertAction) -> Void in
            if let secTxt = alert.textFields?.first?.text {
                if let sec = Double(secTxt) {
                    self.loadRhythm(withPeriod: sec, continuousSweeping: true)
                }
            }
            
        })
        alert.addAction(cancelAction)
        alert.addAction(doneAction)
        alert.addAction(contAction)
        
        self.present(alert, animated: true, completion: nil)
        
        
    }
    
    private func loadRhythm(withPeriod sec : Double, continuousSweeping : Bool) {
        //load selected cells to [Track]
        guard let allTracks = AudioManager.loadTracks() else { return }
        var selectedTracks : [Track] = []
        
        for index in selectedCells {
            let aTrack = allTracks[index]
            selectedTracks.append(aTrack)
        }
        //Rhythm()
        rhythmSession = Rhythm(selectedTracks: selectedTracks, period: sec, sweeping: continuousSweeping)
        _ = rhythmSession!.play()
    }
    
    //MARK: - Stitch controls
    
    @IBAction func stitch(_ sender : Any) {
        
        if stitchOn == true {
            do {
                try AudioKit.stop()
                stitchOn = false
            } catch {
                print(error)
            }
            return
        }
        
        let alert = UIAlertController(title: "Enter period", message: "Please enter the stitching period.", preferredStyle: .alert)
        alert.addTextField(configurationHandler: {(textField) -> Void in
            textField.keyboardType = UIKeyboardType.decimalPad
            textField.keyboardAppearance = UIKeyboardAppearance.dark
            textField.placeholder = "0.50"
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let doneAction = UIAlertAction(title: "Done", style: .default, handler: { (alertAction) -> Void in
            if let secTxt = alert.textFields?.first?.text {
                if let sec = Double(secTxt) {
                    self.startStitching(at: sec)
                }
            }
            
        })
        let gravityAction = UIAlertAction(title: "Gravity", style: .default) { (alertAction) in
            if let secTxt = alert.textFields?.first?.text {
                if let sec = Double(secTxt) {
                    self.startGravity(at: sec)
                }
            }
        }
        
        let crosspanAction = UIAlertAction(title: "Crosspan", style: .default) { (alertAction) in
            if let secTxt = alert.textFields?.first?.text {
                if let sec = Double(secTxt) {
                    self.startCrosspanStitch(at: sec)
                }
            }
        }
        
        alert.addAction(cancelAction)
        alert.addAction(doneAction)
        alert.addAction(gravityAction)
        alert.addAction(crosspanAction)
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    private func startStitching(at period : Double) {
        
        guard let allTracks = AudioManager.loadTracks() else { return }
        let firstTrack : Track = allTracks[selectedCells[0]]
        let secondTrack : Track = allTracks[selectedCells[1]]
        
        do {
            let firstFile = try AKAudioFile(forReading: firstTrack.getURL())
            let secondFile = try AKAudioFile(forReading: secondTrack.getURL())
            let firstPlayer = try AKAudioPlayer(file: firstFile, looping: true, lazyBuffering: false, completionHandler: nil)
            let secondPlayer = try AKAudioPlayer(file: secondFile, looping: true, lazyBuffering: false, completionHandler: nil)
            
            let mixer = AKMixer(firstPlayer, secondPlayer)
            firstPlayer.pan = -1
            secondPlayer.pan = 1
            
            let function = AKPeriodicFunction(every: period, handler: {
                firstPlayer.pan = firstPlayer.pan * -1
                secondPlayer.pan = secondPlayer.pan * -1
            })
            
            AudioKit.output = mixer
            try AudioKit.start(withPeriodicFunctions: function)
            function.start()
            firstPlayer.play()
            secondPlayer.play()
            
            AKSettings.playbackWhileMuted = true
            AKSettings.disableAVAudioSessionCategoryManagement = false
            try AKSettings.setSession(category: AKSettings.SessionCategory.playback, with: .mixWithOthers)
            
            stitchOn = true
        } catch {
            print(error)
        }
    }
    
    private func startGravity(at period : Double) {
        guard let allTracks = AudioManager.loadTracks() else { return }
        let firstTrack : Track = allTracks[selectedCells[0]]
        let secondTrack : Track = allTracks[selectedCells[1]]
        
        do {
            let firstFile = try AKAudioFile(forReading: firstTrack.getURL())
            let secondFile = try AKAudioFile(forReading: secondTrack.getURL())
            let firstPlayer = try AKAudioPlayer(file: firstFile, looping: true, lazyBuffering: false, completionHandler: nil)
            let secondPlayer = try AKAudioPlayer(file: secondFile, looping: true, lazyBuffering: false, completionHandler: nil)
            
            let mixer = AKMixer(firstPlayer, secondPlayer)
            firstPlayer.pan = -1
            secondPlayer.pan = 1
            var wavelength : Double = pi/2
            let function = AKPeriodicFunction(every: period, handler: {
                //left is always negative
                firstPlayer.pan = -absVal(sin(wavelength))
                
                //right is always positive
                secondPlayer.pan = absVal(sin(wavelength))
                
                //wavelength interval
                wavelength = wavelength + (pi/8)
                
            })
            
            AudioKit.output = mixer
            try AudioKit.start(withPeriodicFunctions: function)
            function.start()
            firstPlayer.play()
            secondPlayer.play()
            
            AKSettings.playbackWhileMuted = true
            AKSettings.disableAVAudioSessionCategoryManagement = false
            try AKSettings.setSession(category: AKSettings.SessionCategory.playback, with: .mixWithOthers)
            
            stitchOn = true
        } catch {
            print(error)
        }
    }
    
    private func startCrosspanStitch(at period: Double) {
        guard let allTracks = AudioManager.loadTracks() else { return }
        let firstTrack : Track = allTracks[selectedCells[0]]
        let secondTrack : Track = allTracks[selectedCells[1]]
        
        do {
            let firstFile = try AKAudioFile(forReading: firstTrack.getURL())
            let secondFile = try AKAudioFile(forReading: secondTrack.getURL())
            let firstPlayer = try AKAudioPlayer(file: firstFile, looping: true, lazyBuffering: false, completionHandler: nil)
            let secondPlayer = try AKAudioPlayer(file: secondFile, looping: true, lazyBuffering: false, completionHandler: nil)
            
            let mixer = AKMixer(firstPlayer, secondPlayer)
            firstPlayer.pan = -1
            secondPlayer.pan = 1
            
            var wavelength : Double = 0
            let function = AKPeriodicFunction(every: period, handler: {
                //left and right pans will intersect
                firstPlayer.pan = sin(wavelength)
                secondPlayer.pan = sin(-wavelength)
                
                wavelength = wavelength + (pi/8)
            })
            
            AudioKit.output = mixer
            try AudioKit.start(withPeriodicFunctions: function)
            function.start()
            firstPlayer.play()
            secondPlayer.play()
            
            AKSettings.playbackWhileMuted = true
            AKSettings.disableAVAudioSessionCategoryManagement = false
            try AKSettings.setSession(category: AKSettings.SessionCategory.playback, with: .mixWithOthers)
            
            stitchOn = true
        } catch {
            print(error)
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
// MARK: - Rhythm
class Rhythm : NSObject {
    
    // MARK: - Ivars
    var tracks : [Track]
    var period : Double
    var sweeping : Bool
    var readyToPlay : Bool = false
    
    var files : [AKAudioFile]?
    var currentFileIndex : Int = 0
    
    var audioPlayer : AKAudioPlayer?
    var timer : AKPeriodicFunction?
    var panner : AKPanner?
    var dimPanner : AK3DPanner?
    var isLeft : Bool = true
    
    var isPlaying : Bool {
        get {
            guard let _ = audioPlayer else { return false }
            return audioPlayer!.isPlaying
        }
    }
    // MARK: - Setup controls
    private func loadAudio() -> Bool {
        
        var mutableFiles : [AKAudioFile] = []
        
        for track in tracks {
            let fileURL = documentsDirectory.appendingPathComponent(track.fileName)
            do {
                let aFile = try AKAudioFile(forReading: fileURL)
                mutableFiles.append(aFile)
            } catch let error {
                print(error)
            }
        }
        
        if mutableFiles.isEmpty == false {
            files = mutableFiles
            
            do {
                audioPlayer = try AKAudioPlayer(file: files![0], looping: false, lazyBuffering: false, completionHandler: {
                    
                    if self.currentFileIndex == (self.files!.count - 1) {
                        return
                    }
                    self.nextTrack()
                })
                
                
                if !sweeping {
                    panner = AKPanner(audioPlayer!)
                timer = AKPeriodicFunction(every: period, handler: {
                    switch self.isLeft {
                    case true:
                        self.panner?.pan = 1.0
                        self.isLeft = false
                        break
                        
                    case false:
                        self.panner?.pan = -1.0
                        self.isLeft = true
                        break
                    }
                })
                } else {
                    dimPanner = AK3DPanner.init(audioPlayer!, x: 0, y: 0, z: 0)
                    var time : Double = 0
                    timer = AKPeriodicFunction(every: period, handler: {
                        //let coordinates = lemniscate(forTime: time, amplitude: 14)
                        let coordinates = council(forTime: time, radius: 5)
                        self.dimPanner?.x = coordinates.x
                        self.dimPanner?.y = coordinates.y
                        self.dimPanner?.z = coordinates.z
                        
                        time += (pi/16)
                    })
                }
                AKSettings.playbackWhileMuted = true
                AKSettings.disableAVAudioSessionCategoryManagement = false
                try AKSettings.setSession(category: AKSettings.SessionCategory.playback, with: .mixWithOthers)
                
            } catch let error {
                print(error)
            }
            
            return true
        }
        
        return false
    }
    
    func nextTrack() {
        
        self.currentFileIndex += 1
        let nextFile = self.files![self.currentFileIndex]
        
        do {
            try self.audioPlayer?.replace(file: nextFile)
            _ = self.play()
        } catch let error {
            print(error)
        }
        
    }
    
    // MARK: - Playback controls
    
    func play() -> Bool {
        if readyToPlay != true {
            return false
        }
        guard let _ = audioPlayer else { return false }
        guard let _ = timer else { return false }
        
        if !sweeping {
            guard let _ = panner else { return false }
            AudioKit.output = panner!
        } else {
            guard let _ = dimPanner else { return false }
            AudioKit.output = dimPanner!
        }
        
        
        do {
            try AudioKit.start(withPeriodicFunctions: timer!)
            audioPlayer!.play()
            timer!.start()
            return true
        } catch let error {
            print(error)
            return false
        }
        
        
        
    }
    
    func stop() -> Bool {
        guard let _ = audioPlayer else { return false }
        guard let _ = timer else { return false }
        
        do {
            try AudioKit.stop()
            audioPlayer!.stop()
            timer!.stop()
            return true
        } catch let error {
            print(error)
            return false
        }
        
    }
    
    // MARK: - Initializer
    
    init(selectedTracks: [Track], period sec : Double, sweeping sweep : Bool) {
        tracks = selectedTracks
        period = sec
        sweeping = sweep
        
        super.init()
        
        self.readyToPlay = self.loadAudio()
    }
}

