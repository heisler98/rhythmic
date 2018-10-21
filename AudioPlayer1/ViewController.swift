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

class ViewController: UIViewController, iTunesDelegate, SearchResults {
    
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
    }
    
    func setupNavigationItem() {
        let clear = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(clearSelections(_:)))
        let add = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showMusicLibrary(_:)))
        
        self.navigationItem.setLeftBarButton(clear, animated: false)
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
        return true
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
        let alertController = UIAlertController(title: "New session", message: "Give the new session a name.", preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.keyboardType = UIKeyboardType.alphabet
            textField.keyboardAppearance = UIKeyboardAppearance.alert
        }
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            self.viewModel.buildSession(name: alertController.textFields![0].text!)
            self.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        }))
        self.present(alertController, animated: true, completion: nil)
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
        queue.reset()
        playButtonItem.action = #selector(handlePlayButton(_:))
    }
    ///Updates the info label with the number of queued tracks.
    func updateTrackInfo() {
        infoLabel.text = "\(queue.count) songs selected"
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
    
    @objc func showMusicLibrary(_ sender: Any) {
        performSegue(withIdentifier: "librarySegue", sender: sender)
    }
    // MARK: - Search Results
    ///Handles the selection of a `Track` cell from the search controller.
    /// - parameter selectedTrack: The `Track` object associated with the selected cell.
    func didSelectTrack(_ selectedTrack: Track) {
        searchController.isActive = false

        let allTracks = viewModel.tracks.tracks
        let index = allTracks.index(of: selectedTrack)
        
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
        if segue.identifier! == "sessionSegue" {
            guard let vc = segue.destination as? SessionController else { return }
            guard sender is UITableViewCell else { return }
            guard let path = tableView.indexPath(for: sender! as! UITableViewCell) else { return }
            vc.name = viewModel.sessions[path.row].title
            vc.tracks = viewModel.sessions[path.row].tracks
            vc.sessionPath = path
            vc.masterCollection = viewModel.tracks.tracks
            vc.delegate = viewModel.sessions as SessionResponder
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
            if indexPath.row == viewModel.sessions.count {
                createSession(tableView)
                tableView.deselectRow(at: indexPath, animated: true)
                return
            }
            do {
                self.handler = try viewModel.sessionSelected(at: indexPath.row)
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
            
            queue.cellSelected(at: indexPath.row)
            guard cell != nil else { fatalError("Unexpectedly found nil in unwrapping tableviewcell") }
            viewModel.setupCell(cell!, forIndexPath: indexPath)
            tableView.deselectRow(at: indexPath, animated: true)
            updateTrackInfo()
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
            
            _ = self.viewModel.tracks.remove(at: indexPath.row)
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
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let headerView = view as? UITableViewHeaderFooterView else { return }

        let descriptor = UIFontDescriptor(name: UIFont.ProjectFonts.Regular.rawValue, size: 17)
        let font = UIFont(descriptor: descriptor, size: 17)
        headerView.textLabel?.font = font
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
