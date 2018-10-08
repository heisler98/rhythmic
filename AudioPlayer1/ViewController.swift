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

///Computes a set quantity of random integers in a given range.
/// - returns: An array containing the given quantity of random integers from the specified range.
/// - Parameters:
///   - range: A range of integers to draw at random.
///   - quantity: The amount of integers to draw.
func randsInRange(range: Range<Int>, quantity : Int) -> [Int] {
    var rands : [Int] = []
    for _ in 0..<quantity {
        rands.append(Int(arc4random_uniform(UInt32(range.upperBound - range.lowerBound))) + range.lowerBound)
    }
    return rands
}

class ViewController: UIViewController, iTunesDelegate, SearchResults {
    
    // MARK: - Private property controls
    ///The playback handler for the set of selected tracks. Set at play-time.
    var handler : PlaybackHandler?
    ///The view model for the view controller.
    var viewModel : ViewModel
    ///A reference to the queue contained in `ViewModel`.
    var queue : Queue
    
    // MARK: - IBOutlets
    @IBOutlet weak var customNavItem: UINavigationItem!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var playBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var distanceItem : UIBarButtonItem!
    @IBOutlet weak var entrainItem : UIBarButtonItem!
    
    ///The search controller used for searching through `Track`s.
    var searchController : UISearchController
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    // MARK: - View controls
    
    override func viewDidLoad() {
        super.viewDidLoad()
        customNavItem.searchController = searchController
        definesPresentationContext = true
    }

    // MARK: - New track from OpenURL
    
    ///Builds a new `Track` and passes it to `TrackManager` within `ViewModel`.
    /// - returns: A Boolean value indicating whether the `Track` was successfully added.
    /// - parameters:
    ///    - url: The URL of the audio file asset.
    func newTrack(at url: URL) -> Bool {
        let lastComponent = url.pathComponents.last!
        let firstDot = lastComponent.index(of: ".") ?? lastComponent.endIndex
        let fileName = lastComponent[..<firstDot]
        
        let alert = UIAlertController(title: "Period", message: "Enter the desired period or BPM for the piece '\(fileName)'.", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.keyboardType = .decimalPad
        }
        
        let action = UIAlertAction(title: "Done", style: .default, handler: {(alertAction) -> Void in
            
            if let period = alert.textFields?.first?.text {
                var doublePeriod : Double
                
                if Double(period)! < 10 {
                    doublePeriod = Double(period)!
                } else {
                    doublePeriod = 1/((Double(period)!)/60)
                }
            
                
            let newTrack = Track(title: String(fileName), period: doublePeriod, fileName: lastComponent)
            self.viewModel.tracks.append(track: newTrack)
            self.tableView.reloadData()
        }})
        //copyAction for track|file disparity – will not add new track to AM
        let copyAction = UIAlertAction(title: "Copy Only", style: .destructive, handler: nil)
        
        alert.addAction(action)
        alert.addAction(copyAction)
        self.present(alert, animated: true, completion: {() -> Void in })
        return true
    }

    // MARK: - UI funcs
    ///Intercepts the handling of the play button being pushed.
    /// - parameters:
    ///     - sender: `Any` sender of the play button action.
    @IBAction func handlePlayButton(_ sender: Any) {
        if handler == nil {
            handler = try? viewModel.playbackHandler()
            handler?.startPlaying()
            return
        }
        
        if handler!.isPlaying {
            handler!.stopPlaying()
            handler = nil
            queue.reset()
        }
        
    }
    ///Intercepts the shuffle button being pushed.
    /// - parameters:
    ///     - sender: `Any` sender of the shuffle action.
    @IBAction func randomShuffle(_ sender: Any) {
        
        let alertController = UIAlertController(title: "Shuffle tracks", message: "Enter the number of tracks to shuffle.", preferredStyle: .alert)
        let doneAction = UIAlertAction(title: "Done", style: .default) { (alertAction) in
            
            guard let quantity = Int((alertController.textFields?.first?.text)!) else { return }
            guard quantity <= self.viewModel.tracks.count else { return }
            
            self.startShuffle(quantity: quantity)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addTextField { (textField) in
            textField.keyboardType = .numberPad
        }
        alertController.addAction(doneAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    ///Selects shuffled tracks and begins playback.
    /// - parameter quantity: The number of shuffled tracks to draw.
    private func startShuffle(quantity : Int) {
        guard quantity <= self.viewModel.tracks.count else { return }
        let chosen = randsInRange(range: 0..<self.viewModel.tracks.count, quantity: quantity)
        self.queue.append(all: chosen)
        self.handler = nil
        self.handler = try? self.viewModel.playbackHandler()
        self.handler?.startPlaying()
    }
    ///Clears all selected tracks from the queue, and reloads the table view.
    /// - parameter sender: `Any` sender of the clear button being pushed.
    @IBAction func clearSelections(_ sender: Any) {
        queue.reset()
        self.tableView.reloadData()
    }
    
    @IBAction func distanceChanged(_ sender: UISlider) {
        //affects crosspan only
        absoluteDistance = sender.value
        distanceItem.title = String(format: "%.2f", absoluteDistance)
    }

    @IBAction func stitch(_ sender: Any) {
        if queue.isEmpty {
        // do nothing
            return
        }
        
        let massChange : (Rhythmic) -> Void = { (rhythm) in
            for index in self.queue {
                self.viewModel.tracks[index].rhythm = rhythm
                let indexPath = IndexPath(row: index, section: 1)
                let cell = self.tableView.cellForRow(at: indexPath)
                cell?.detailTextLabel?.text = self.viewModel.detailString(for: index)
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
    
    @IBAction func createSession(_ sender : Any) { // add tvc and show keyboard edit directly in cell? would require uitextfield
        guard viewModel.queue.selectedTracks.isEmpty != true else { return }
        let someTracks = viewModel.tracks.tracks(forIndices: viewModel.queue.selectedTracks)
        let newSession = Session(tracks: someTracks, title: "New session")
        viewModel.sessions.add(newSession)
        tableView.reloadData()
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
    ///Handles the selection of a `Track` cell from the search controller.
    /// - parameter selectedTrack: The `Track` object associated with the selected cell.
    func didSelectTrack(_ selectedTrack: Track) {
        searchController.isActive = false

        let allTracks = viewModel.tracks.tracks
        guard let index = allTracks.index(of: selectedTrack) else { return }
        
        queue.safeSelectCell(at: index)
        
        let indexPath = IndexPath(row: index, section: 1)
        tableView.reloadRows(at: [indexPath], with: .none)
        tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let _ = segue.identifier else { return }
        if segue.identifier! == "librarySegue" {
            guard let vc = segue.destination as? LibraryController else { return }
            vc.delegate = self as iTunesDelegate
        }
    }
    
    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let resultsController = storyboard.instantiateViewController(withIdentifier: "searchResults") as! SearchTableController
        searchController = UISearchController(searchResultsController: resultsController)
        searchController.searchResultsUpdater = resultsController
        
        viewModel = ViewModel()
        queue = viewModel.queue
        
        super.init(coder: aDecoder)
        
        resultsController.delegate = self as SearchResults
    }
    
}
// MARK: - ViewController tableView extension
extension ViewController : UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            do {
                let handler = try viewModel.sessionSelected(at: indexPath.row)
                handler.startPlaying()
            } catch {
                fatalError("\(error)")
            }
        }
        
        if indexPath.section == 1 {
            let cell = tableView.cellForRow(at: indexPath)
            
            queue.cellSelected(at: indexPath.row)
            guard cell != nil else { fatalError("Unexpectedly found nil in unwrapping tableviewcell") }
            viewModel.setupCell(cell!, forIndexPath: indexPath)
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    /**
    Handles the rhythm change of a `Track` at a designated `IndexPath`.
     
     - parameters:
    
         - rhythm: A new rhythm.
         - atIndexPath: The selected index path.
         - completionHandler: The closure passed in from a
    `UISwipeActionsConfiguration`.
     
     Changing the rhythm of a `Track` object requires setting the proper case on the track inside `TrackManager`, then updating the table view accordingly. Call this function when the rhythm is changed from a UI interaction.
 */
    fileprivate func rhythmChange(_ rhythm : Rhythmic, atIndexPath indexPath : IndexPath, _ completionHandler: (Bool) -> Void) {
        
        viewModel.tracks[indexPath.row].rhythm = rhythm
        completionHandler(true)
        
        let cell = tableView.cellForRow(at: indexPath)
        cell?.detailTextLabel?.text = viewModel.detailString(for: indexPath.row)
        
        selected:
            if !queue.contains(indexPath.row) {
            queue.cellSelected(at: indexPath.row)
            guard cell != nil else { break selected }
            viewModel.setupCell(cell!, forIndexPath: indexPath)
        }
    }
    /**
     Sets up and returns a `UISwipeActionsConfiguration` object to delete the `Track` at a specified index.
     
     - parameter forIndexPath: The index path of the `Track` to delete
     - returns: A `UISwipeConfiguration` object for processing deletion.
 */
    fileprivate func deleteSessionSwipeConfig(forIndexPath indexPath : IndexPath) -> UISwipeActionsConfiguration {
        let delete = UIContextualAction(style: .destructive, title: "Delete") { (_, _, completionHandler) in
            let alert = UIAlertController(title: "Delete session", message: "Are you sure you want to delete this session?", preferredStyle: UIAlertController.Style.alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (action) in
                
                //delete track
                _ = self.viewModel.sessions.delete(session: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
                completionHandler(true)
                
            })
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alert.addAction(okAction)
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        }
        let config = UISwipeActionsConfiguration(actions: [delete])
        config.performsFirstActionWithFullSwipe = true
        return config
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if indexPath.section == 0 { return deleteSessionSwipeConfig(forIndexPath: indexPath) }
        
        let bilateral = UIContextualAction(style: .normal, title: "Bilateral", handler: { _, _, completionHandler in
            self.rhythmChange(.Bilateral, atIndexPath: indexPath, completionHandler) })
        bilateral.backgroundColor = UIColor.green
        
        let crosspan = UIContextualAction(style: .normal, title: "Crosspan", handler: { _, _, completionHandler in
            self.rhythmChange(.Crosspan, atIndexPath: indexPath, completionHandler) })
        crosspan.backgroundColor = UIColor.purple
        
        let synthesis = UIContextualAction(style: .normal, title: "Synthesis", handler: { _, _, completionHandler in
            self.rhythmChange(.Synthesis, atIndexPath: indexPath, completionHandler) })
        synthesis.backgroundColor = UIColor.blue
        
        let stitch = UIContextualAction(style: .normal, title: "Swave", handler: { _, _, completionHandler in
            self.rhythmChange(.Stitch, atIndexPath: indexPath, completionHandler) })
        stitch.backgroundColor = UIColor.gray
        
        let delete = UIContextualAction(style: .destructive, title: "Delete") { _, _, completionHandler in
            
            let alert = UIAlertController(title: "Delete track", message: "Are you sure you want to delete this track?", preferredStyle: UIAlertController.Style.alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (action) in

                _ = self.viewModel.tracks.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
                completionHandler(true)
                
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
    /**
     Handles the rate change of a `Track` at a specified index path.
     - parameters:
     
        - rate: A new rate.
        - atIndexPath: The index path of the `Track`.
        - completionHandler: A closure passed in from a `UISwipeActionsConfiguration` object.
 */
    fileprivate func rateChange(_ rate : PanRate, atIndexPath indexPath : IndexPath, _ completionHandler: (Bool) -> Void) {
        
        viewModel.tracks[indexPath.row].rate = rate
        completionHandler(true)
        let cell = tableView.cellForRow(at: indexPath)
        cell?.detailTextLabel?.text = viewModel.detailString(for: indexPath.row)
        
        selected:
            if !queue.contains(indexPath.row) {
            queue.cellSelected(at: indexPath.row)
            guard cell != nil else { break selected }
            viewModel.setupCell(cell!, forIndexPath: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if indexPath.section == 0 { return nil }
        
        let half = UIContextualAction(style: .normal, title: "0.5x", handler: { _, _, completionHandler in
            self.rateChange(.Half, atIndexPath: indexPath, completionHandler) })
        half.backgroundColor = UIColor.red
        
        let normal = UIContextualAction(style: .normal, title: "1x", handler: { _, _, completionHandler in
            self.rateChange(.Normal, atIndexPath: indexPath, completionHandler) })
        normal.backgroundColor = UIColor.gray
        
        let double = UIContextualAction(style: .normal, title: "2x", handler: { _, _, completionHandler in
            self.rateChange(.Double, atIndexPath: indexPath, completionHandler) })
        double.backgroundColor = UIColor.blue
        
        let quad = UIContextualAction(style: .normal, title: "4x", handler: { action, view, completionHandler in
            self.rateChange(.Quad, atIndexPath: indexPath, completionHandler) })
        quad.backgroundColor = UIColor.purple
        
        let config = UISwipeActionsConfiguration(actions: [half, normal, double, quad])
        config.performsFirstActionWithFullSwipe = false
        return config
        
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    // MARK: - Table View data source controls
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 { return "Sessions" }
        if section == 1 { return "Songs" }
        return nil
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return viewModel.sessions.count }
        if section == 1 { return viewModel.tracks.count }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        viewModel.setupCell(cell, forIndexPath: indexPath)
        return cell
    }
}

protocol SearchResults {
    func didSelectTrack(_ selectedTrack : Track)
}
// MARK: - Search table view controller

class SearchTableController : UITableViewController, UISearchResultsUpdating {
    ///The tracks returned from filtering all available tracks.
    var filteredTracks = TrackArray()
    ///All tracks available to the application.
    var allTracks : TrackArray!
    ///The delegate object for handling selection.
    var delegate : SearchResults?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        allTracks = TrackManager().tracks
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContent(forSearchText: searchController.searchBar.text!)
    }
    
    func filterContent(forSearchText searchText : String) {
        filteredTracks = allTracks.filter({ (track) -> Bool in
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

