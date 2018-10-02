//
//  PanAudioPlayer.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 7/14/17.
//  Copyright © 2017 Hunter Eisler. All rights reserved.
//  Unauthorized copying of this file via any medium is strictly prohibited.
//  *Proprietary and confidential*

import UIKit
import AVFoundation
import MediaPlayer
import os.log

// MARK: - Global definitions

typealias TrackArray = Array<Track>
let pi = 3.14159265
var absoluteDistance : Float = 0.87

func absVal(_ param : Double) -> Double {
    if param < 0 {
        return -param
    }
    return param
}

// MARK: - Enums

enum Rhythmic : Int, Codable {
    case Bilateral = 0
    case Crosspan
    case Synthesis
    case Stitch //Swave
    
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

enum PanRate : Int, Codable {
    case Half = 0
    case Normal
    case Double
    case Quad
    
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

enum HandlerError : Error {
    /// Unexpectedly found nil in this data type
    case UnexpectedlyFoundNil(Any)
    /// No data found at specified path
    case NoDataFound(String)
}

//MARK: - PanAudioPlayer
class PanAudioPlayer: AVAudioPlayer {

    // MARK: - Property controls
    private var timer : Timer = Timer()
    private var period : Double
    var trackIndex : Int?
    
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
    
    func invalidateRhythm() {
        timer.invalidate()
    }
    
    func setupRhythm(_ opt: Rhythmic) {
        
        if (opt == .Bilateral) { //phi
            self.pan = -1
            self.timer = Timer.scheduledTimer(withTimeInterval: period, repeats: true, block: { (timer : Timer) -> Void in
            
                self.pan *= -1
            })
            
        }
        
        else if (opt == .Crosspan) { //delta
            self.pan = PrefsHandler().prefs["slider_crosspan"] ?? 0.87
  
            //self.pan = absoluteDistance
            self.timer = Timer.scheduledTimer(withTimeInterval: period, repeats: true, block: { (timer : Timer) -> Void in
                
                self.pan *= -1
                
            })
            
        } else if (opt == .Synthesis) { //sigma
            
            //pan = 0
            self.pan = 0
            self.timer = Timer.scheduledTimer(withTimeInterval: self.period, repeats: true, block: {(timer : Timer) -> Void in
                
                // do nothing
            })
            
        } else if (opt == .Stitch) { //gamma
            
            var wavelength : Double = 0
            self.timer = Timer.scheduledTimer(withTimeInterval: self.period, repeats: true, block: { (timer : Timer) -> Void in
                let newVal = Float(sin(wavelength))
                wavelength += (pi/16)
                guard absVal(Double(newVal)) < 0.9 else { return }
                self.pan = newVal
                
            
            })
        }

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
struct Track : Codable {
   
    var title : String
    var period : Double
    var category : String
    
    let fileName : String //includes extension
    
    var rhythm : Rhythmic
    var rate : PanRate
    
    var url : URL {
        get {
            return DataHandler.documentsDirectory.appendingPathComponent(fileName)
        }
    }
    
    // MARK: - Audio player
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
public struct Session : Codable {
    var tracks : [Track]
    var title : String
    
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
struct ViewModel {
    var tracks = TrackManager()
    var sessions = SessionManager()
    private var trackQueue = Queue()
    var queue : Queue {
        get {
            return trackQueue
        }
    }
    /// Returns the detail string for track at the specified index.
    func detailString(for index: Index) -> String {
        let aTrack = tracks[index]
        let rhythm = aTrack.rhythm.descriptor()
        let rate : String = aTrack.rate.descriptor()
        
        let amendedPeriod = aTrack.period.toPanRate(aTrack.rate)
        let perStr = String(format: "%.3f", amendedPeriod)
        
        return "\(rhythm) : \(rate) : \(perStr)"
    }
    
    func title(for index : IndexPath) -> String {
        if index.section == 0 { return sessions[index.row].title }
        if index.section == 1 { return tracks[index.row].title }
        return ""
    }

    // MARK: - Setup cells
    private func setupSelectedCell(_ cell : UITableViewCell) {
        cell.accessoryType = .checkmark
        let color = UIColor(red: 1, green: 0.4, blue: 0.4, alpha: 1.0)
        cell.textLabel?.textColor = color
        cell.tintColor = color
    }
    
    private func setupUnselectedCell(_ cell : UITableViewCell) {
        cell.accessoryType = .none
        cell.textLabel?.textColor = UIColor.black
    }
    
    func setupCell(_ cell : UITableViewCell, forIndexPath indexPath : IndexPath) {
        if indexPath.section == 0 {
            cell.textLabel!.text = sessions[indexPath.row].title
            cell.detailTextLabel!.text = "\(sessions.count) songs"
        }
        
        if indexPath.section == 1 {
            cell.textLabel!.text = tracks[indexPath.row].title
            cell.detailTextLabel!.text = self.detailString(for: indexPath.row)
            
            if queue.contains(indexPath.row) {
                setupSelectedCell(cell)
            } else {
                setupUnselectedCell(cell)
            }
        }
    }
    
    // MARK: - Playback
    /// Returns an instantiated `PlaybackHandler` object.
    func playbackHandler() throws -> PlaybackHandler {
        do {
            return try PlaybackHandler(queue: queue, tracks: tracks)
        } catch {
            throw error
        }
    }
    
    func sessionSelected(at index : Index) throws -> PlaybackHandler {
        let tracksToPlay = sessions[index].tracks
        for track in tracksToPlay {
            guard let index = tracks.tracks.firstIndex(of: track) else { continue }
            queue.append(selected: index)
        }
        return try playbackHandler()
    }

}

// MARK: - Queue
/// Type for queue construction to pass to PlaybackHandler
class Queue : Sequence, IteratorProtocol {
    typealias Element = Index
    
    var selectedTracks = [Index]()
    
    private var position : Position
    var queued : [Index]? {
        get {
            if isEmpty == true { return nil }
            return selectedTracks
        }
    }
    var isEmpty : Bool {
        get {
            return selectedTracks.isEmpty
        }
    }
    
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
    func append(selected : Index) {
        selectedTracks.append(selected)
    }
    
    func append(all : [Index]) {
        selectedTracks.append(contentsOf: all)
    }
    
    func remove(selected : Index) -> Index? {
        if selectedTracks.contains(selected) {
            return selectedTracks.remove(at: selectedTracks.firstIndex(of: selected)!)
        }
        return nil
    }
    
    func removeAll() {
        selectedTracks.removeAll()
    }
    
    func contains(_ index : Index) -> Bool {
        return selectedTracks.contains(index)
    }
    
    // MARK: - Selected cells
    func cellSelected(at index : Index) {
        if selectedTracks.contains(index) {
            _ = self.remove(selected: index)
        } else {
            self.append(selected: index)
        }
    }
    
    /// Only append index if not already present; will not remove index if selected. Non-destructive.
    func safeSelectCell(at index : Index) {
        if !contains(index) {
            selectedTracks.append(index)
        }
    }
    
    fileprivate init() {
        position = 0
    }
}
