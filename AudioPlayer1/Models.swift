//  (Formerly PanAudioPlayer.swift)
//  Models.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 7/14/17.
//  Copyright © 2017 Hunter Eisler. All rights reserved.
//  Unauthorized copying of this file via any medium is strictly prohibited.
//  *Proprietary and confidential*

import UIKit
import AVFoundation
import MediaPlayer

// MARK: - Global definitions

typealias TrackArray = Array<Track>
let pi = 3.14159265

/**
 Calculates and returns the absolute value of a `Double`.
 - returns: The absolute value of the argument.
 - parameter param: An initial value.
 */
func absVal(_ param : Double) -> Double {
    if param < 0 {
        return -param
    }
    return param
}

// MARK: - Enums
///An enumeration of available rhythms for a `Track`.
enum Rhythmic : Int, Codable {
    case Bilateral = 0
    case Crosspan
    case Synthesis
    case Stitch //Swave
    
    /**
     Computes a human-readable expression of the current case.
     - returns: A string containing the description of the case.
 */
    func descriptor() -> String {
        switch self.rawValue {
        case 0:
            return "Bilateral"
        case 1:
            return "Crosspan"
        case 2:
            return "Synthesis"
        case 3:
            return "Swave"
        default:
            return ""
        }
    }
}
///An enumeration of the available rates for a `Track`.
enum PanRate : Int, Codable {
    case Half = 0
    case Normal
    case Double
    case Quad
    
    /**
     Computes a human-readable expression of the current case.
     - returns: A string containing the description of the case.
     */
    func descriptor() -> String {
        switch self.rawValue {
        case 0:
            return "0.5x"
        case 1:
            return "1x"
        case 2:
            return "2x"
        case 3:
            return "4x"
        default:
            return ""
        }
    }
}
///An enumeration of the possible handler errors.
enum HandlerError : Error {
    /// Unexpectedly found nil in this data type
    case UnexpectedlyFoundNil(Any)
    /// No data found at specified path
    case NoDataFound(String)
}
///An enumeration of table view cell identifiers. 
enum CellIdentifiers : String {
    case Session = "sessionCell"
    case Track = "cell"
    case Library = "songCell"
    case TrackInSession = "trackCell"
}

extension UIFont {
    enum ProjectFonts: String {
        typealias RawValue = String
        
        case Regular = "AvenirNext-Regular"
        case Italic = "AvenirNext-Italic"
        case DemiBold = "AvenirNext-DemiBold"
        case DemiBoldItalic = "AvenirNext-DemiBoldItalic"
        case HeavyItalic = "AvenirNext-HeavyItalic"
        case Medium = "AvenirNext-Medium"
    }
}

extension UIColor {
    ///The local project color swatch.
    static var swatch : UIColor {
        get {
            return UIColor(red: 1, green: 0.4, blue: 0.4, alpha: 1.0)
        }
    }
    ///The local project translucent color swatch.
    static var translucentSwatch : UIColor {
        get {
            return UIColor(red: 1, green: 0.4, blue: 0.4, alpha: 0.7)
        }
    }
}
///A protocol for receiving playback progress.
protocol ProgressUpdater: AnyObject {
    /**
     Tells the delegate object the current playback progress.
     - parameter to: The playback progress indicated between 0.0 and 1.0.
 */
    func updateProgress(to fractionalUnit : Float)
}
//MARK: - PanAudioPlayer
///Subclass of `AVAudioPlayer` supporting bilateral pan.
class PanAudioPlayer: AVAudioPlayer {

    // MARK: - Property controls
    ///The timer controlling the panning frequency.
    private var timer : Timer = Timer()
    ///The period/(frequency) of the pan.
    private var period : Double
    ///The progress delegate.
    weak var progressDelegate : ProgressUpdater?
    
    // MARK: - Playback controls
    
    override func play() -> Bool {
        timer.fire()
        return super.play()
    }
    
    override func stop() {
        timer.invalidate()
        super.stop()
    }
    
    // MARK: - Rhythm controls
    ///Invalidates the `Timer` and removes it from the `RunLoop`.
    func invalidateRhythm() {
        timer.invalidate()
    }
    /**
     Sets up the audio player with the proper rhythm.
     - parameter opt: The rhythm from the `Track` object.
 */
    func setupRhythm(_ opt: Rhythmic) {
        
        if (opt == .Bilateral) { //phi
            self.pan = -1
            self.timer = Timer.scheduledTimer(withTimeInterval: period, repeats: true, block: { (timer : Timer) -> Void in
                self.pan *= -1
                self.progressDelegate?.updateProgress(to: Float(self.currentTime / self.duration))
            })
        }
        
        else if (opt == .Crosspan) { //delta
            self.pan = PrefsHandler().prefs["slider_crosspan"] ?? 0.87
  
            //self.pan = absoluteDistance
            self.timer = Timer.scheduledTimer(withTimeInterval: period, repeats: true, block: { (timer : Timer) -> Void in
                self.pan *= -1
                self.progressDelegate?.updateProgress(to: Float(self.currentTime / self.duration))
            })
            
        } else if (opt == .Synthesis) { //sigma
            
            //pan = 0
            self.pan = 0
            self.timer = Timer.scheduledTimer(withTimeInterval: self.period, repeats: true, block: {(timer : Timer) -> Void in
                self.progressDelegate?.updateProgress(to: Float(self.currentTime / self.duration))
                // do nothing
            })
            
        } else if (opt == .Stitch) { //gamma
            
            var wavelength : Double = 0
            self.timer = Timer.scheduledTimer(withTimeInterval: self.period, repeats: true, block: { (timer : Timer) -> Void in
                let newVal = Float(sin(wavelength))
                wavelength += (pi/16)
                guard absVal(Double(newVal)) < 0.9 else { return }
                self.pan = newVal
                self.progressDelegate?.updateProgress(to: Float(self.currentTime / self.duration))
            
            })
        }

    }
    // MARK: - Progress updating
    /**
     Calculates the playback progress of the current player.
     - returns: A value between 0.0 and 1.0 indicating progress.
 */
    func progress() -> Float {
        return Float(currentTime / duration)
    }
    // MARK: - Inits
    init(contentsOf url: URL, period: Double) throws {
        self.period = period
        do {
            try super.init(contentsOf: url, fileTypeHint: url.pathExtension)
        } catch let error as NSError {
            throw error
        }
    }
}

// MARK: - Track
///A type holding the available values of a track.
struct Track : Codable {
    ///The title of a track.
    var title : String
    ///The period of a track, calculated from tempo.
    var period : Double
    ///The category of a track. (Unused.)
    var category : String
    ///The file name of the asset of a track.
    let fileName : String //includes extension
    ///The rhythm of a track.
    var rhythm : Rhythmic
    ///The rate of a track.
    var rate : PanRate
    ///The URL of the represented asset.
    var url : URL {
        get {
            return DataHandler.documentsDirectory.appendingPathComponent(fileName)
        }
    }
    
    // MARK: - Audio player
    ///The audio player associated with the track.
    lazy var audioPlayer: PanAudioPlayer? = {
        do {
            let val = try PanAudioPlayer(contentsOf: self.url, period: self.period.toPanRate(self.rate))
            return val
        } catch {
            print(error)
            return nil
        }
        
    }()

    init(title : String, period : Double, category : String = "song", fileName : String, rhythm : Rhythmic = .Bilateral, rate : PanRate = .Normal) {
        
        self.title = title
        self.period = period
        self.category = category
        self.fileName = fileName
        self.rhythm = rhythm
        self.rate = rate
    }
}

extension Track : Equatable {
    
    static func == (lTrack : Track, rTrack : Track) -> Bool {
        return lTrack.title == rTrack.title && lTrack.period == rTrack.period && lTrack.category == rTrack.category && rTrack.fileName == lTrack.fileName
    }
}

extension Double {
    /**
     Computes a new `Double` based on the given rate.
     - returns: A `Double` mutated by a rate.
     - parameter rate: The rate with which to mutate the given value.
 */
    func toPanRate(_ rate : PanRate) -> Double {
        switch rate {
        case .Double:
            return self / 2
            
        case .Half:
            return self * 2
            
        case .Quad:
            return self / 4
            
        default:
            return self
        }
    }
}
// MARK: - Session
typealias Tag = Int
///A type holding the values for a session.
public struct Session : Codable {
    ///The collection of `Track`s composing a session.
    var tracks : [Track]
    ///The title of the session.
    var title : String
    ///The number of tracks in the session. (Convenience).
    var count : Int {
        get {
            return tracks.count
        }
    }
    
    init(tracks: [Track], title: String) {
        self.tracks = tracks
        self.title = title
    }
}

extension Session : Equatable {
    public static func == (lhs : Session, rhs : Session) -> Bool {
        return lhs.title == rhs.title && lhs.tracks == rhs.tracks
    }
}

// MARK: - ViewModel
///The model used to construct the view.
struct ViewModel {
    ///A manager for track objects.
    var tracks = TrackManager()
    ///A manager for session objects.
    var sessions = SessionManager()
    ///Private queue var
    private var trackQueue = Queue()
    ///The queue of selected tracks.
    var queue : Queue {
        get {
            return trackQueue
        }
    }
    ///Indicates whether a Session can be built.
    var canBuildSession : Bool {
        if trackQueue.isEmpty == true { return false }
        return true
    }
    
    var sorter = SortHandler(enumerated: TrackManager().enumerated)
    // MARK: - Modeling the view
    
    /// Returns the detail string for track at the specified index.
    /// - parameter index: The index of the track object.
    /// - returns: A rhythm-rate string.
    func detailString(for index: Index) -> String {
        let aTrack = tracks[index]
        let rhythm = aTrack.rhythm.descriptor()
        let rate : String = aTrack.rate.descriptor()
        
        let amendedPeriod = aTrack.period.toPanRate(aTrack.rate)
        let perStr = String(format: "%.3f", amendedPeriod)
        
        return "\(rhythm) : \(rate) : \(perStr)"
    }
    /**
     Returns the title of a track at the specified index.
     - parameter for: The index path of the track.
     - returns: The title of the track.
 */
    func title(for indexPath : IndexPath) -> String {
        if indexPath.section == 0 { return sessions[indexPath.row].title }
        if indexPath.section == 1 { return tracks[indexPath.row].title }
        return ""
    }
    /**
     Selects a given quantity of random tracks.
     - parameter quantity: The number of tracks to randomly select.
     
     This method does not instantiate a PlaybackHandler. After calling, use `playbackHandler()`.
 */
    func shuffle(quantity: Int) {
        guard quantity <= tracks.count else { return }
        let range = 0..<quantity
        var randoms = [Index]()
        for _ in range {
            randoms.append(Int.random(in: range))
        }
        queue.append(all: randoms)
    }
    // MARK: - Building models
    /**
     Builds a Track and adds it to the TrackManager.
     - parameters:
     
        - url: The URL of the track.
        - periodOrBPM: The user-inputted period or tempo of the track.
     
     If the entered period/tempo value is greater than 10, the method assumes the entered value was a tempo.
 */
    func buildTrack(url : URL, periodOrBPM: Double) {
        let lastComponent = url.pathComponents.last!
        let firstDot = lastComponent.index(of: ".") ?? lastComponent.endIndex
        let fileName = lastComponent[..<firstDot]
        var period : Double
        
        if periodOrBPM > 10 {
            period = 1/(periodOrBPM / 60)
        } else {
            period = periodOrBPM
        }
        
        let track = Track(title: String(fileName), period: period, fileName: lastComponent)
        tracks.append(track: track)
        sorter.updateEnumerated(tracks.enumerated)
        _ = DataHandler.setPreferredFileProtection(on: url)
    }
    /**
     Builds a Session and adds it to the SessionManager.
     - parameter name: The name for the new session.
 */
    func buildSession(name: String) {
        let selectedTracks = tracks.tracks(forIndices: queue.selectedTracks)
        let session = Session(tracks: selectedTracks, title: name)
        sessions.add(session)
        
    }
    func sort(by descriptor: SortHandler.Descriptor) {
        sorter.by = descriptor
    }
    // MARK: - Track changes
    /**
     Sets a new rhythm to the specified index, taking the current sort option into account.
     - Parameters:
     
        - rhythm: The new rhythm.
        - index: The index of the cell.
 */
    func setRhythm(_ rhythm: Rhythmic, for index: Index) {
        let masterIndex = sorter.masterIndex(for: index)
        tracks[masterIndex].rhythm = rhythm
        sorter.sorted[index].element.rhythm = rhythm
    }
    /**
     Sets a new rate to the specified index, taking the current sort option into account.
     - Parameters:
     
        - rate: The new rate.
        - index: The index of the cell.
 */
    func setRate(_ rate: PanRate, for index: Index) {
        let masterIndex = sorter.masterIndex(for: index)
        tracks[masterIndex].rate = rate
        sorter.sorted[index].element.rate = rate
    }
    /**
 */
    func removeTrack(at index: Index) -> Track {
        let masterIndex = sorter.masterIndex(for: index)
        sessions.deleteEvery(tracks[masterIndex])
        defer {
            sorter.updateEnumerated(tracks.enumerated)
        }
        return tracks.remove(at: masterIndex)
    }
    /**
 */
    func index(of track: Track) -> Index? {
        return sorter.index(of: track)
    }
    
    // MARK: - Setup cells
    /**
     Sets up the properties of a `UITableViewCell` to represent a selected state.
     - parameter cell: The cell to modify.
 */
    private func setupSelectedCell(_ cell : UITableViewCell) {
        cell.accessoryType = .checkmark
        cell.textLabel?.textColor = UIColor.swatch
        cell.tintColor = UIColor.swatch
    }
    /**
     Sets up the properties of a `UITableViewCell` to represent an unselected state.
     - parameter cell: The cell to modify.
 */
    private func setupUnselectedCell(_ cell : UITableViewCell) {
        cell.accessoryType = .none
        cell.textLabel?.textColor = UIColor.black
        
    }
    /**
     Modifies a cell with the proper configuration based on the current queue of selected tracks.
     - Parameters:
     
        - cell: The cell to modify.
        - indexPath: The index path of the cell.
 */
    func setupCell(_ cell : UITableViewCell, forIndexPath indexPath : IndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == sessions.count {
                cell.textLabel!.text = "Create a new session..."
                cell.detailTextLabel?.text = ""
                cell.accessoryType = .none
                return
            }
            cell.textLabel!.text = sessions[indexPath.row].title
            cell.detailTextLabel!.text = "\(sessions[indexPath.row].count) songs"
            cell.accessoryType = .detailButton
            
        }
        
        if indexPath.section == 1 {
            cell.textLabel?.text = sorter.sorted[indexPath.row].element.title
            cell.detailTextLabel?.text = self.detailString(for: sorter.sorted[indexPath.row].offset)
            
            if queueContains(indexPath.row) {
                setupSelectedCell(cell)
            } else {
                setupUnselectedCell(cell)
            }
        }
    }
    /**
     A wrapper for Queue.safeSelectCell(at:) that takes the set `SortDescriptor` into account.
     - parameter index: The index of the cell.
 */
    func safeSelectCell(at index: Index) {
        let masterIndex = sorter.masterIndex(for: index)
        queue.safeSelectCell(at: masterIndex)
    }
    /**
     A wrapper for Queue.cellSelected(at:) that takes the set `SortDescriptor` into account.
     - parameter index: The index of the cell.
 */
    func cellSelected(at index: Index) {
        let masterIndex = sorter.masterIndex(for: index)
        queue.cellSelected(at: masterIndex)
    }
    /**
 */
    func queueContains(_ index: Index) -> Bool {
        let masterIndex = sorter.masterIndex(for: index)
        return queue.contains(masterIndex)
    }
    // MARK: - Playback
    /**
    Loads an instantiated `PlaybackHandler` from the current queue.
     - returns: A `PlaybackHandler` object.
     - throws: Throws a `HandlerError` case if the `PlaybackHandler` cannot be instantiated with the current queue.
 */
    func playbackHandler() throws -> PlaybackHandler {
        do {
            queue.hasChangedSincePlayback = false
            return try PlaybackHandler(queue: queue, tracks: tracks)
        } catch {
            queue.hasChangedSincePlayback = true
            throw error
        }
    }
    
    /**
     Loads an instantiated `PlaybackHandler` from the selected session.
     - returns: A `PlaybackHandler` object.
     - parameter index: The index of the session.
     - throws: Throws a `HandlerError` case if the `PlaybackHandler` cannot be instantiated with the selected session.
 */
    func sessionSelected(at index : Index, shuffled: Bool) throws -> PlaybackHandler {
        var tracksToPlay = sessions[index].tracks
        if shuffled == true { tracksToPlay.shuffle() }
        let sessionQueue = Queue()
        let manager = SessionTrackManager(tracks: tracksToPlay)
        sessionQueue.append(all: Array(tracksToPlay.indices))
        do {
            queue.hasChangedSincePlayback = false
            return try PlaybackHandler(queue: sessionQueue, tracks: manager)
        } catch {
            queue.hasChangedSincePlayback = true
            throw error
        }
    }
}

// MARK: - Queue
/// Type for queue construction to pass to `PlaybackHandler`.
class Queue : Sequence, IteratorProtocol {
    typealias Element = Index
    ///An array of selected indices.
    var selectedTracks = [Index]()
    ///The current position for iteration.
    private var position : Position
    ///Indicates whether the queue has been changed since playback.
    var hasChangedSincePlayback : Bool = true
    ///An optional, computed array of selected indices.
    var queued : [Index]? {
        get {
            if isEmpty == true { return nil }
            return selectedTracks
        }
    }
    ///The number of queued indices.
    var count : Int {
        get {
            return queued?.count ?? 0
        }
    }
    ///Tells if `selectedTracks` is empty.
    var isEmpty : Bool {
        get {
            return selectedTracks.isEmpty
        }
    }
    ///The `QueueUpdater` delegate.
    var delegate : QueueUpdater?
    /**
     A subscript getter and setter.
     - parameter position: The position in the queue to access.
     - returns: The index at the position.
 */
    subscript(position : Position) -> Index {
        get {
            return selectedTracks[position]
        } set {
            selectedTracks[position] = newValue
        }
    }
    // MARK: - Iteration
    func next() -> Index? {
        if position == selectedTracks.endIndex-1 {
            return nil
        }
        defer { position += 1 }
        return selectedTracks[position]
    }
    
    
    // MARK: - Selected tracks
    /**
     Appends an index to the queue.
     - parameter selected: The index to append.
 */
    func append(selected : Index) {
        hasChangedSincePlayback = true
        selectedTracks.append(selected)
        notifyDelegate()
    }
    /**
     Appends an array of indices to the end of the queue.
     - parameter all: The indices to append.
 */
    func append(all : [Index]) {
        hasChangedSincePlayback = true
        selectedTracks.append(contentsOf: all)
        notifyDelegate()
    }
    /**
     Removes an index from the queue.
     - parameter selected: The index to remove.
     - returns: The removed index.
 */
    func remove(selected : Index) -> Index? {
        if selectedTracks.contains(selected) {
            hasChangedSincePlayback = true
            defer { notifyDelegate() }
            return selectedTracks.remove(at: selectedTracks.firstIndex(of: selected)!)
        }
        return nil
    }
    /**
     Clears the entire queue by removing all indices.
 */
    func reset() {
        hasChangedSincePlayback = true
        selectedTracks.removeAll()
        notifyDelegate()
    }
    /**
     Tells whether the queue contains a specified index.
     - parameter index: The index in question.
     - returns: A Boolean indicating whether the index is present.
 */
    func contains(_ index : Index) -> Bool {
        return selectedTracks.contains(index)
    }

    // MARK: - Selected cells
    /**
     Interprets the selection of a cell.
     - parameter index: The index of the cell.
     
     This method will only toggle the presence of the index in the queue. This method does not modify the cell itself.
 */
    func cellSelected(at index : Index) {
        if selectedTracks.contains(index) {
            hasChangedSincePlayback = true
            _ = self.remove(selected: index)
            notifyDelegate()
        } else {
            hasChangedSincePlayback = true
            self.append(selected: index)
            notifyDelegate()
        }
    }
    
    /// Only append index if not already present; will not remove index if selected. Non-destructive.
    /// - parameter index: The selected index.
    func safeSelectCell(at index : Index) {
        if !contains(index) {
            hasChangedSincePlayback = true
            selectedTracks.append(index)
            notifyDelegate()
        }
        
    }
    
    func notifyDelegate() {
        delegate?.notify()
    }
    
    init() {
        position = 0
    }
}
