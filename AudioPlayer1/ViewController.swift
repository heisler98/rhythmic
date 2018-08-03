//
//  ViewController.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 11/3/16.
//  Copyright © 2016-2017 Hunter Eisler. All rights reserved.
//  Unauthorized copying of this file via any medium is strictly prohibited.
//  *Proprietary and confidential*

// **Potentials**
// ?: Collection view REM/stitch "sessions"/groups/categories/ - organized by speed etc

import UIKit
import AVFoundation
import MediaPlayer
import os.log
import WebKit


func randsInRange(range: Range<Int>, quantity : Int) -> [Int] {
    
    var rands : [Int] = []
    for _ in 0..<quantity {
        rands.append(Int(arc4random_uniform(UInt32(range.upperBound - range.lowerBound))) + range.lowerBound)
    }
    return rands
}

protocol iTunesDelegate {
    func dismissed(withURL : URL?)
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AudioManagerDelegate, iTunesDelegate, SearchResults {
    
    // MARK: - Private property controls
    private var audioManager = AudioManager.shared
    private var selectedCells : Array<Int> = []
    
    // MARK: - IBOutlets
    @IBOutlet weak var customNavItem: UINavigationItem!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var playBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var distanceItem : UIBarButtonItem!
    
    var searchController : UISearchController
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    // MARK: - View controls
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let tracks = AudioManager.loadTracks() {
            try? audioManager.setTracks(tracks)
        }
        audioManager.delegate = self as AudioManagerDelegate
        audioManager.setupRemoteControlEvents()
        
        customNavItem.searchController = searchController
        definesPresentationContext = true
        
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
        alert.addTextField { (textField) in
            textField.keyboardType = .asciiCapableNumberPad
        }
        
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
            
                
            self.audioManager.add(newTrack: newTrack)
            self.tableView.reloadData()
                
            
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
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return audioManager.trackCount
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return "Tracks"
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.textLabel?.text = audioManager.title(forIndex: indexPath.row)
        cell.detailTextLabel?.text = audioManager.rhythmRate(forIndex: indexPath.row)
        
        if (selectedCells.contains(indexPath.row)) {
            cell.accessoryType = .checkmark
            cell.textLabel?.textColor = UIColor(red:1, green: 0.4, blue: 0.4, alpha: 1.0)
            cell.tintColor = UIColor(red: 1, green: 0.4, blue: 0.4, alpha: 1.0)
        } else {
            cell.accessoryType = .none
            cell.textLabel?.textColor = UIColor.black
        }

        return cell
        
    }
    
    // MARK: - Table View delegate controls
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
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
            cell?.textLabel?.textColor = UIColor(red:1, green: 0.4, blue: 0.4, alpha: 1.0)
            cell?.tintColor = UIColor(red: 1, green: 0.4, blue: 0.4, alpha: 1.0)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
   
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        return true
    }
    
   
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
            let bilateral = UIContextualAction(style: .normal, title: "Bilateral", handler: { action, view, completionHandler in
                
                self.audioManager.setRhythm(Rhythmic.Bilateral, forIndex:indexPath.row)
                completionHandler(true)
                //self.tableView.reloadRows(at: [indexPath], with: .none)
                let cell = tableView.cellForRow(at: indexPath)
                cell?.detailTextLabel?.text = self.audioManager.rhythmRate(forIndex: indexPath.row)
                if cell?.accessoryType != .checkmark {
                    cell?.accessoryType = .checkmark
                    cell?.textLabel?.textColor = UIColor(red:1.0, green: 0.4, blue: 0.4, alpha: 1.0)
                    self.selectedCells.append(indexPath.row)
                }
            })
            bilateral.backgroundColor = UIColor.green
            
            let crosspan = UIContextualAction(style: .normal, title: "Crosspan", handler: { action, view, completionHandler in
                
                self.audioManager.setRhythm(Rhythmic.Crosspan, forIndex:indexPath.row)
                completionHandler(true)
                let cell = tableView.cellForRow(at: indexPath)
                cell?.detailTextLabel?.text = self.audioManager.rhythmRate(forIndex: indexPath.row)
                if cell?.accessoryType != .checkmark {
                    cell?.accessoryType = .checkmark
                    cell?.textLabel?.textColor = UIColor(red:1.0, green: 0.4, blue: 0.4, alpha: 1.0)
                    self.selectedCells.append(indexPath.row)
                }
            })
            crosspan.backgroundColor = UIColor.purple
            
            let synthesis = UIContextualAction(style: .normal, title: "Synthesis", handler: { action, view, completionHandler in
                
                self.audioManager.setRhythm(Rhythmic.Synthesis, forIndex:indexPath.row)
                completionHandler(true)
                let cell = tableView.cellForRow(at: indexPath)
                cell?.detailTextLabel?.text = self.audioManager.rhythmRate(forIndex: indexPath.row)
                if cell?.accessoryType != .checkmark {
                    cell?.accessoryType = .checkmark
                    cell?.textLabel?.textColor = UIColor(red:1.0, green: 0.4, blue: 0.4, alpha: 1.0)
                    self.selectedCells.append(indexPath.row)
                }
            })
            synthesis.backgroundColor = UIColor.blue
            
            let stitch = UIContextualAction(style: .normal, title: "Swave", handler: { action, view, completionHandler in
                
                self.audioManager.setRhythm(Rhythmic.Stitch, forIndex:indexPath.row)
                completionHandler(true)
                let cell = tableView.cellForRow(at: indexPath)
                cell?.detailTextLabel?.text = self.audioManager.rhythmRate(forIndex: indexPath.row)
                if cell?.accessoryType != .checkmark {
                    cell?.accessoryType = .checkmark
                    cell?.textLabel?.textColor = UIColor(red:1.0, green: 0.4, blue: 0.4, alpha: 1.0)
                    self.selectedCells.append(indexPath.row)
                }
            })
            stitch.backgroundColor = UIColor.gray
        
        let delete = UIContextualAction(style: .destructive, title: "Delete") { action, view, completionHandler in
            
                let alert = UIAlertController(title: "Delete track", message: "Are you sure you want to delete this track?", preferredStyle: UIAlertControllerStyle.alert)
                let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action) in
                  
                    let success = self.audioManager.deleteTrack(atIndex: indexPath.row)
                    
                    if success == true {
                        self.tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
                    }
                    completionHandler(success)
                    
                })
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                alert.addAction(okAction)
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            
            
            
        }
            let config = UISwipeActionsConfiguration(actions: [bilateral, synthesis, crosspan, stitch, delete])
            config.performsFirstActionWithFullSwipe = false
            return config
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        
        
            let half = UIContextualAction(style: .normal, title: "0.5x", handler: { action, view, completionHandler in
                
                self.audioManager.setRate(PanRate.Half, forIndex: indexPath.row)
                completionHandler(true)
                let cell = tableView.cellForRow(at: indexPath)
                cell?.detailTextLabel?.text = self.audioManager.rhythmRate(forIndex: indexPath.row)
                if cell?.accessoryType != .checkmark {
                    cell?.accessoryType = .checkmark
                    cell?.textLabel?.textColor = UIColor(red:1.0, green: 0.4, blue: 0.4, alpha: 1.0)
                    self.selectedCells.append(indexPath.row)
                }
            })
            half.backgroundColor = UIColor.red
            
            let normal = UIContextualAction(style: .normal, title: "1x", handler: { action, view, completionHandler in
                
                self.audioManager.setRate(PanRate.Normal, forIndex: indexPath.row)
                completionHandler(true)
                let cell = tableView.cellForRow(at: indexPath)
                cell?.detailTextLabel?.text = self.audioManager.rhythmRate(forIndex: indexPath.row)
                if cell?.accessoryType != .checkmark {
                    cell?.accessoryType = .checkmark
                    cell?.textLabel?.textColor = UIColor(red:1.0, green: 0.4, blue: 0.4, alpha: 1.0)
                    self.selectedCells.append(indexPath.row)
                }
            })
            normal.backgroundColor = UIColor.gray
            
            let double = UIContextualAction(style: .normal, title: "2x", handler: { action, view, completionHandler in
                
                self.audioManager.setRate(PanRate.Double, forIndex: indexPath.row)
                completionHandler(true)
                let cell = tableView.cellForRow(at: indexPath)
                cell?.detailTextLabel?.text = self.audioManager.rhythmRate(forIndex: indexPath.row)
                if cell?.accessoryType != .checkmark {
                    cell?.accessoryType = .checkmark
                    cell?.textLabel?.textColor = UIColor(red:1.0, green: 0.4, blue: 0.4, alpha: 1.0)
                    self.selectedCells.append(indexPath.row)
                }
            })
            double.backgroundColor = UIColor.blue
            
            let quad = UIContextualAction(style: .normal, title: "4x", handler: { action, view, completionHandler in
                
                self.audioManager.setRate(PanRate.Quad, forIndex: indexPath.row)
                completionHandler(true)
                let cell = tableView.cellForRow(at: indexPath)
                cell?.detailTextLabel?.text = self.audioManager.rhythmRate(forIndex: indexPath.row)
                if cell?.accessoryType != .checkmark {
                    cell?.accessoryType = .checkmark
                    cell?.textLabel?.textColor = UIColor(red:1.0, green: 0.4, blue: 0.4, alpha: 1.0)
                    self.selectedCells.append(indexPath.row)
                }
            })
            quad.backgroundColor = UIColor.purple
            
            let config = UISwipeActionsConfiguration(actions: [half, normal, double, quad])
            config.performsFirstActionWithFullSwipe = false
            return config
    
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    // MARK: - UI Controls
    @IBAction func handlePlayButton(_ sender: Any) {
        
        if (selectedCells.isEmpty == true) {
            if (audioManager.isPlaying == true) {
                audioManager.stopPlayback()
                
            }
            return
        }
            
        if (audioManager.isPlaying == false) {
            _ = audioManager.playback(queued: selectedCells)
        } else {
            audioManager.stopPlayback()
        }
        
    }
    
    @IBAction func randomShuffle(_ sender: Any) {
        
        let alertController = UIAlertController(title: "Shuffle tracks", message: "Enter the number of tracks to shuffle.", preferredStyle: .alert)
        let doneAction = UIAlertAction(title: "Done", style: .default) { (alertAction) in
            
            guard let quantity = Int((alertController.textFields?.first?.text)!) else { return }
            guard quantity <= self.audioManager.trackCount else { return }
            
            var chosen = randsInRange(range: 0..<self.audioManager.trackCount, quantity: quantity)
            if !self.selectedCells.isEmpty {
                chosen.insert(contentsOf: self.selectedCells, at: 0)
            }
            _ = self.audioManager.playback(queued: chosen)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addTextField { (textField) in
            textField.keyboardType = .numberPad
        }
        alertController.addAction(doneAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func clearSelections(_ sender: Any) {
        
        selectedCells.removeAll(keepingCapacity: true)
        self.tableView.reloadData()
    
    }
    
    @IBAction func distanceChanged(_ sender: UISlider) {
        
        //affects crosspan only
        absoluteDistance = sender.value
        distanceItem.title = String(format: "%.2f", absoluteDistance)
        
    }
    
    @IBAction func stitch(_ sender: Any) {
        if selectedCells.count == 0 {
        // do nothing
            return
        }
        
        let massChange : (Rhythmic) -> Void = { (rhythm) in
            for index in self.selectedCells {
                self.audioManager.setRhythm(rhythm, forIndex: index)
                let indexPath = IndexPath(row: index, section: 0)
                let cell = self.tableView.cellForRow(at: indexPath)
                cell?.detailTextLabel?.text = self.audioManager.rhythmRate(forIndex: index)
            }
        }
        
        let alertController = UIAlertController(title: "Change rhythms", message: "Choose the new rhythm for all selected cells.", preferredStyle: .alert)
        let bilateralAction = UIAlertAction(title: "Bilateral", style: .default) { (action) in
            massChange(.Bilateral)
            self.dismiss(animated: true, completion: nil)
        }
        let crosspanAction = UIAlertAction(title: "Crosspan", style: .default) { (action) in
            massChange(.Crosspan)
            self.dismiss(animated: true, completion: nil)
        }
        let synthesisAction = UIAlertAction(title: "Synthesis", style: .default) { (action) in
            massChange(.Synthesis)
            self.dismiss(animated: true, completion: nil)
        }
        
        alertController.addAction(crosspanAction)
        alertController.addAction(bilateralAction)
        alertController.addAction(synthesisAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - AudioManager delegate controls
    func audioManagerDidCompletePlaylist() { 
       audioManager.repeatQueue()
    }
    
    func audioManagerPlaybackInterrupted() {
        
    }
    
    // MARK: - iTunes delegate controls
    func dismissed(withURL: URL?) {
        
        self.dismiss(animated: true, completion: nil)
        guard let assetURL = withURL else { return }
        
        
        switch self.newTrack(at: assetURL) {
        case true: break
        case false:
            do {
            try FileManager.default.removeItem(at: assetURL)
            } catch { print(error) }
            break
        }
    }
    // MARK: - Search Results
    func didSelectTrack(_ selectedTrack: Track) {
        
        //dismiss search controller
        searchController.isActive = false
        
        //find track index
        guard let allTracks = AudioManager.loadTracks() else { return }
        guard let index = allTracks.index(of: selectedTrack) else { return }
        
        //select chosen cell
        selectedCells.append(index)
        
        //show chosen track
        let indexPath = IndexPath(row: index, section: 0)
        tableView.reloadRows(at: [indexPath], with: .none)
        tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let _ = segue.identifier else { return }
        if segue.identifier! == "librarySegue" {
            guard let vc = segue.destination as? LibraryController else { return }
            vc.delegate = self as iTunesDelegate
        }
        
        if segue.identifier! == "showSession" {
            guard let vc = segue.destination as? SessionViewController else { return }
            
            vc.delegate = audioManager
            audioManager.remDelegate = vc
        }
      
    }
    
    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let resultsController = storyboard.instantiateViewController(withIdentifier: "searchResults") as! SearchTableController
        searchController = UISearchController(searchResultsController: resultsController)
        searchController.searchResultsUpdater = resultsController
        
        super.init(coder: aDecoder)
        
        resultsController.delegate = self as SearchResults
    }
}

class SearchTableController : UITableViewController, UISearchResultsUpdating {
    
    var filteredTracks = TrackArray()
    var allTracks : TrackArray?
    var delegate : SearchResults?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let _ = AudioManager.loadTracks() else { print("Cannot load tracks for search"); return }
        allTracks = AudioManager.loadTracks()!
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContent(forSearchText: searchController.searchBar.text!)
    }
    
    func filterContent(forSearchText searchText : String) {
        
        guard let _ = allTracks else { print("Did not load tracks for search; cannot filter"); return }
        filteredTracks = allTracks!.filter({ (track) -> Bool in
            return track.title.lowercased().contains(searchText.lowercased())
        })
        
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "searchCell") else { fatalError("Cannot dequeue reusable cell")}
        
        let track = filteredTracks[indexPath.row]
        cell.textLabel?.text = track.title
        
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredTracks.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let _ = delegate else { return }
        delegate!.didSelectTrack(filteredTracks[indexPath.row])
    }
}

protocol SearchResults {
    func didSelectTrack(_ selectedTrack : Track)
}
