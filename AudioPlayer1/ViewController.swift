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

///Computes a set quantity of random integers in a given range.
/// - returns: An array containing the given quantity of random integers from the specified range.
/// - Parameters:
///   - range: A range of integers to draw at random.
///   - quantity: The amount of integers to draw.
func randsInRange(range: Range<Int>, quantity : Int) -> [Int] {
    var rands = [Int]()
    for _ in 0..<quantity {
        rands.append(Int.random(in: range))
    }
    return rands
}

class ViewController: UIViewController, iTunesDelegate, SearchResults, InlinePlayback {
    
    // MARK: - Private property controls
    ///The playback handler for the set of selected tracks. Set at play-time.
    var handler : PlaybackHandler?
    ///The view model for the view controller.
    var viewModel : ViewModel
    ///A reference to the queue contained in `ViewModel`.
    var queue : Queue
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var playButtonItem: UIBarButtonItem!
    @IBOutlet weak var progressView : UIProgressView!
    
    ///The search controller used for searching through `Track`s.
    var searchController : UISearchController
    ///Indicates whether a drawer is present.
    var isDrawerPresent = false
    /*
    override var prefersStatusBarHidden: Bool {
        return false
    }
 */
    // MARK: - View controls
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationItem()
        self.navigationItem.searchController = searchController
        
        searchController.searchBar.tintColor = UIColor.white
    
        playButtonItem.target = self
        playButtonItem.action = #selector(handlePlayButton(_:))
        
        definesPresentationContext = true
        tableView.separatorColor = UIColor.swatch
        tableView.backgroundView = nil
        tableView.backgroundColor = UIColor.swatch
    }
    
    func setupNavigationItem() {
        let clear = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(clearSelections(_:)))
        let add = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showMusicLibrary(_:)))
        let sort = UIBarButtonItem(title: "Sort", style: .plain, target: self, action: #selector(sort(_:)))
        let fixedSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        fixedSpace.width = 15
        
        self.navigationItem.setLeftBarButtonItems([clear, fixedSpace, sort], animated: false)
        self.navigationItem.setRightBarButton(add, animated: false)
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
        
        if let bpm = TempoHandler.core.tempo(of: url, completion: nil) {
            viewModel.buildTrack(url: url, periodOrBPM: bpm)
            tableView.reloadData()
            return true
        } else {
            requestPeriod(of: String(fileName), at: url)
            return true
        }
    }
    
    /**
 */
    func requestPeriod(of fileName: String, at url: URL) {
        let alert = UIAlertController(title: "Period", message: "Enter the desired period or BPM for the piece '\(fileName)'.", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.keyboardType = .decimalPad
        }
        let action = UIAlertAction(title: "Done", style: .default, handler: {(alertAction) -> Void in
            
            if let period = alert.textFields?.first?.text {
                guard let periodOrBPM = Double(period) else { return }
                self.viewModel.buildTrack(url: url, periodOrBPM: periodOrBPM)
                self.tableView.reloadData()
            }})
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }

    // MARK: - UI funcs
    ///Intercepts the handling of the play button being pushed.
    /// - parameters:
    ///     - sender: `Any` sender of the play button action.
    @IBAction func handlePlayButton(_ sender: Any) {
        handler = try? viewModel.playbackHandler()
        handler?.progressReceiver = self as ProgressUpdater
        handler?.startPlaying()
        playButtonItem.action = #selector(stop(_:))
    }
    ///Intercepts the shuffle button being pushed.
    /// - parameters:
    ///     - sender: `Any` sender of the shuffle action.
    @IBAction func randomShuffle(_ sender: Any) {
        
        let alertController = UIAlertController(title: "Shuffle tracks", message: "Enter the number of tracks to shuffle.", preferredStyle: .alert)
        let doneAction = UIAlertAction(title: "Done", style: .default) { (alertAction) in
            
            guard let quantity = Int((alertController.textFields?.first?.text)!) else { return }
            
            self.viewModel.shuffle(quantity: quantity)
            self.handlePlayButton(self)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addTextField { (textField) in
            textField.keyboardType = .numberPad
        }
        alertController.addAction(doneAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    ///Clears all selected tracks from the queue, and reloads the table view.
    /// - parameter sender: `Any` sender of the clear button being pushed.
    @IBAction func clearSelections(_ sender: Any) {
        queue.reset()
        updateTrackInfo()
        progressView.setProgress(0, animated: false)
        self.tableView.reloadData()
 
    }
    /**
     Creates a session.
     - parameter sender: The sender of the action.
 */
    @IBAction func createSession(_ sender : Any) {
        guard viewModel.canBuildSession == true else { return }
        guard isDrawerPresent == false else { return } 
/*        let alertController = UIAlertController(title: "New session", message: "Give the new session a name.", preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.keyboardType = UIKeyboardType.alphabet
            textField.keyboardAppearance = UIKeyboardAppearance.alert
        }
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            self.viewModel.buildSession(name: alertController.textFields![0].text!)
            self.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        }))
        self.present(alertController, animated: true, completion: nil)
 */
        guard let trackDrawerController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TrackDrawer") as? TrackDrawerController else { return }
        trackDrawerController.viewModel = viewModel
        
        displayInDrawer(trackDrawerController, drawerPositionDelegate: self)
        isDrawerPresent = true
        
        
    }
    ///Skip the current track.
    @IBAction func fastForward(_ sender: Any) {
        handler?.skip()
    }
    ///Rewind the track, or skip to the previous track.
    @IBAction func rewind(_ sender: Any) {
        handler?.rewind()
    }
    ///Stop the currently playing `PlaybackHandler` and reset the queue.
    @objc func stop(_ sender: Any) {
        handler?.stopPlaying()
        handler = nil
        clearSelections(sender)
        playButtonItem.action = #selector(handlePlayButton(_:))
    }
    ///Updates the info label with the number of queued tracks.
    func updateTrackInfo() {
        infoLabel.text = "\(queue.count) songs selected"
    }
    ///Handles a request for sorting tracks.
    @objc func sort(_ sender: Any) {
        let alertController = UIAlertController(title: "Sort tracks", message: nil, preferredStyle: .actionSheet)
        let alphaAction = UIAlertAction(title: "Alphabetically", style: .default) { _ in
            self.viewModel.sort(by: .Lexicographic)
            self.tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
        }
        let normalAction = UIAlertAction(title: "Date added", style: .default) { _ in
            self.viewModel.sort(by: .DateAddedDescending)
            self.tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
        }
        let tempoAction = UIAlertAction(title: "By tempo", style: .default) { _ in
            self.viewModel.sort(by: .Tempo)
            self.tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(alphaAction)
        alertController.addAction(normalAction)
        alertController.addAction(tempoAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    /**
     Updates the info label with the name of the `Session`.
     - parameter sessionName: The name of the selected `Session`.
 */
    func updateInfo(sessionName: String) {
        infoLabel.text = sessionName
    }
    
    // MARK: - iTunes delegate controls
    func dismissed(withURL: URL?) {
        //self.dismiss(animated: true, completion: nil)
        guard let assetURL = withURL else { return }
        
        switch self.newTrack(at: assetURL) {
        case true: break
        case false:
            do {
            try FileManager.default.removeItem(at: assetURL)
            } catch { dLog(error) }
            break
        }
    }
    
    func dismissed(withURL: URL, period: Double) {
        //self.dismiss(animated: true, completion: nil)
        viewModel.buildTrack(url: withURL, periodOrBPM: period)
        tableView.reloadData()
    }
    
    @objc func showMusicLibrary(_ sender: Any) {
        guard isDrawerPresent == false else { return }
        guard let libraryController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "musicLibrary") as? MusicDrawerController else {
                return
            }
        libraryController.delegate = self as iTunesDelegate
        displayInDrawer(libraryController, drawerPositionDelegate: self)
        
    }
    // MARK: - Search Results
    ///Handles the selection of a `Track` cell from the search controller.
    /// - parameter selectedTrack: The `Track` object associated with the selected cell.
    func didSelectTrack(_ selectedTrack: Track) {
        searchController.isActive = false

        guard let index = viewModel.index(of: selectedTrack) else { return }
        viewModel.safeSelectCell(at: index)
        
        let indexPath = IndexPath(row: index, section: 1)
        tableView.reloadRows(at: [indexPath], with: .none)
        tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        updateTrackInfo()
    }
    // MARK: - Inline playback
    func beginSession(indexPathOf indexPath: IndexPath, at position: Position) {
        do {
            stop(self)
            self.handler = try viewModel.sessionSelected(at: indexPath.row, shuffled: false)
            handler?.progressReceiver = self
            handler?.play(at: position)
            playButtonItem.action = #selector(stop(_:))
            updateInfo(sessionName: viewModel.title(for: indexPath))
        } catch {
            dLog(error)
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
        resultsController.allTracks = viewModel.tracks.tracks
        super.init(coder: aDecoder)
        
        resultsController.delegate = self as SearchResults
        searchController.delegate = self
    }
    
}
// MARK: - ViewController tableView extension
extension ViewController : UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == viewModel.sessions.count {
                createSession(tableView)
                tableView.deselectRow(at: indexPath, animated: true)
                return
            }

            do {
                stop(tableView)
                self.handler = try viewModel.sessionSelected(at: indexPath.row, shuffled: false)
                handler?.progressReceiver = self as ProgressUpdater
                handler?.startPlaying()
                playButtonItem.action = #selector(stop(_:))
                updateInfo(sessionName: viewModel.title(for: indexPath))
                tableView.deselectRow(at: indexPath, animated: true)
 
            } catch {
                fatalError("\(error)")
            }
 }
        
        if indexPath.section == 1 {
            let cell = tableView.cellForRow(at: indexPath)
            
            viewModel.cellSelected(at: indexPath.row)
            guard cell != nil else { fatalError("Unexpectedly found nil in unwrapping tableviewcell") }
            viewModel.setupCell(cell!, forIndexPath: indexPath)
            tableView.deselectRow(at: indexPath, animated: true)
            updateTrackInfo()
/*
            if queue.count == 1 && isDrawerPresent == false {
                guard let trackDrawer = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TrackDrawer") as? TrackDrawerController else { return }
                trackDrawer.viewModel = viewModel
                displayInDrawer(trackDrawer, drawerPositionDelegate: self)
                isDrawerPresent = true
            }
 */
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
        
        viewModel.setRhythm(rhythm, for: indexPath.row)
        completionHandler(true)
        
        let cell = tableView.cellForRow(at: indexPath)
        
        viewModel.safeSelectCell(at: indexPath.row)
        guard cell != nil else { return }
        viewModel.setupCell(cell!, forIndexPath: indexPath)
        updateTrackInfo()
        
    }
    /**
     Sets up and returns a `UISwipeActionsConfiguration` object to delete the `Track` at a specified index.
     
     - parameter forIndexPath: The index path of the `Track` to delete
     - returns: A `UISwipeConfiguration` object for processing deletion.
 */
    fileprivate func deleteSessionSwipeConfig(forIndexPath indexPath : IndexPath) -> UISwipeActionsConfiguration {
        let delete = UIContextualAction(style: .destructive, title: "Delete") { (_, _, completionHandler) in
            let alert = UIAlertController(title: nil, message: "Are you sure you want to delete this session?", preferredStyle: UIAlertController.Style.actionSheet)
            let okAction = UIAlertAction(title: "Yes", style: UIAlertAction.Style.destructive, handler: { (action) in
                
                //delete track
                _ = self.viewModel.sessions.delete(session: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
                completionHandler(true)
                
            })
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                self.tableView.setEditing(false, animated: true)
                completionHandler(false)
            })
            alert.addAction(okAction)
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        }
        let config = UISwipeActionsConfiguration(actions: [delete])
        config.performsFirstActionWithFullSwipe = false
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
            self.delete(atIndexPath: indexPath, completionHandler: completionHandler)
        }
    
        let config = UISwipeActionsConfiguration(actions: [bilateral, synthesis, crosspan, stitch, delete])
        config.performsFirstActionWithFullSwipe = false
        return config
    }
    /**
     Deletes a track at the specified IndexPath.
     - parameters:
     
        - indexPath: An IndexPath to delete.
        - completionHandler: The completionHandler of the contextual action.
 */
    func delete(atIndexPath indexPath: IndexPath, completionHandler : @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: "Are you sure you want to delete this track?", preferredStyle: UIAlertController.Style.actionSheet)
        let okAction = UIAlertAction(title: "Yes", style: UIAlertAction.Style.destructive, handler: { (action) in
            
            _ = self.viewModel.removeTrack(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
            completionHandler(true)
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            self.tableView.setEditing(false, animated: true)
            completionHandler(false)
        })
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    /**
     Handles the rate change of a `Track` at a specified index path.
     - parameters:
     
        - rate: A new rate.
        - atIndexPath: The index path of the `Track`.
        - completionHandler: A closure passed in from a `UISwipeActionsConfiguration` object.
 */
    fileprivate func rateChange(_ rate : PanRate, atIndexPath indexPath : IndexPath, _ completionHandler: (Bool) -> Void) {
        
        viewModel.setRate(rate, for: indexPath.row)
        completionHandler(true)
        let cell = tableView.cellForRow(at: indexPath)
        
        viewModel.safeSelectCell(at: indexPath.row)
        guard cell != nil else { return }
        viewModel.setupCell(cell!, forIndexPath: indexPath)
        updateTrackInfo()
        
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if indexPath.section == 0 && indexPath.row != viewModel.sessions.count {
            let shuffle = UIContextualAction(style: .normal, title: "Shuffle") { (_, _, completionHandler) in
                do {
                    self.stop(tableView)
                    self.handler = try self.viewModel.sessionSelected(at: indexPath.row, shuffled: true)
                    self.handler?.progressReceiver = self as ProgressUpdater
                    self.handler?.startPlaying()
                    self.playButtonItem.action = #selector(self.stop(_:))
                    self.updateInfo(sessionName: self.viewModel.title(for: indexPath))
                    completionHandler(true)
                } catch {
                    dLog(error)
                    completionHandler(true)
                }
            }
            shuffle.backgroundColor = UIColor.swatch
            let config = UISwipeActionsConfiguration(actions: [shuffle])
            config.performsFirstActionWithFullSwipe = true
            return config
        }
        
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
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let headerView = view as? UITableViewHeaderFooterView else { return }

        let descriptor = UIFontDescriptor(name: UIFont.ProjectFonts.Regular.rawValue, size: 17)
        let font = UIFont(descriptor: descriptor, size: 17)
        headerView.textLabel?.font = font
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        if isDrawerPresent == false {
            guard let drawerController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Drawer") as? DrawerController else { return }
            drawerController.delegate = viewModel.sessions as SessionResponder
            drawerController.inlineDelegate = self
            drawerController.masterCollection = viewModel.tracks.tracks
            drawerController.tracks = viewModel.sessions[indexPath.row].tracks
            drawerController.name = viewModel.sessions[indexPath.row].title
            drawerController.sessionPath = indexPath
        
            displayInDrawer(drawerController, drawerPositionDelegate: self)
            isDrawerPresent = true
        }
    }
    
    // MARK: - Table View data source controls
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            if viewModel.sessions.count == 0 { return nil }
            return "Sessions"
        }
        if section == 1 { return "Songs" }
        return nil
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return viewModel.sessions.count + 1 }
        if section == 1 { return viewModel.tracks.count }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell : UITableViewCell
        if indexPath.section == 0 {
            cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.Session.rawValue, for: indexPath)
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.Track.rawValue, for: indexPath)
        }
        viewModel.setupCell(cell, forIndexPath: indexPath)
        return cell
    }
}

extension ViewController : ProgressUpdater {
    func updateProgress(to fractionalUnit: Float) {
        progressView.setProgress(fractionalUnit, animated: false)
    }
}

extension ViewController : DrawerPositionDelegate {
    func didMoveDrawerToTopPosition() {
    }
    
    func didMoveDrawerToMiddlePosition() {
    }
    
    func didMoveDrawerToBasePosition() {
    }
    
    func willDismissDrawer() {
        tableView.reloadData()
    }
    
    func didDismissDrawer() {
        isDrawerPresent = false
    }
    
    
}

extension ViewController : UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
        guard let resultsController = searchController.searchResultsUpdater as? SearchTableController else { return }
        resultsController.allTracks = viewModel.tracks.tracks
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
        let descriptor = UIFontDescriptor(name: UIFont.ProjectFonts.Regular.rawValue, size: 18)
        cell.textLabel?.font = UIFont(descriptor: descriptor, size: 18)
        
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
