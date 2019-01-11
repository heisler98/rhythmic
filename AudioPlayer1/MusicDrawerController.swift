//
//  MusicDrawerController.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 10/25/18.
//  Copyright © 2018 Hunter Eisler. All rights reserved.
//

import UIKit
import MediaPlayer

///A protocol for responding to new music items.
protocol iTunesDelegate : AnyObject {
    /**
     Indicates the view controller completed an import.
     - parameter withURL: The URL of the import, or nil if the import failed.
 */
    func dismissed(withURL : URL?)
    /**
     Indicates the view controller successfully completed importing and analyzed the tempo.
     - Parameters:
        - withURL: The URL of the imported asset.
        - period: The period of the asset. ``(60/BPM)``
 */
    func dismissed(withURL: URL, period: Double)
    /**
     Indicates the view controller found a new file and successfully analyzed the tempo.
     - parameters:
        - url: The URL of the found asset.
        - period: The period of the asset. ``(60/BPM)``
 */
    func found(_ url: URL, period: Double)
    
}

class MusicDrawerController: UIViewController {

    @IBOutlet var gestureRecognizer: UIPanGestureRecognizer!
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var label: UILabel!
    
    weak var delegate : iTunesDelegate?
    var songs = [MPMediaItem]()
    var newFilesPresent = false
    var files = [String]()
    
    var drawerDismissClosure: (() -> Void)?
    var didChangeLayoutClosure: (() -> Void)?
    var panGestureTarget: Any?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        let query = MPMediaQuery.songs()
        let predicate = MPMediaPropertyPredicate(value: false, forProperty: MPMediaItemPropertyIsCloudItem)
        query.addFilterPredicate(predicate)
        guard let items = query.items else { return }
        for item in items where item.hasProtectedAsset == false {
            songs.append(item)
        }
        if let newFiles = FileFinder().newFiles() {
            newFilesPresent = true
            files = newFiles
        }
        tableView.reloadData()
    }
    
    func setupViews() {
        view.backgroundColor = UIColor.clear
        tableView.separatorColor = UIColor.swatch
        tableView.backgroundView = nil
        tableView.backgroundColor = UIColor(white: 1.0, alpha: 0.25)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        didChangeLayoutClosure?()
    }
    
    @IBAction func dismiss(_ sender: Any) {
        drawerDismissClosure?()
    }
}

extension MusicDrawerController : UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return (newFilesPresent == true) ? 2 : 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if songs.isEmpty {
                return 1
            }
            return songs.count
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.Library.rawValue, for: indexPath)
            cell.backgroundView = nil
            cell.backgroundColor = nil
            cell.contentView.backgroundColor = UIColor(white: 1.0, alpha: 0.25)
            cell.textLabel?.text = "Import new songs from File Sharing"
            cell.detailTextLabel?.text = ""
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.Library.rawValue, for: indexPath)
        cell.backgroundView = nil
        cell.backgroundColor = nil
        cell.contentView.backgroundColor = UIColor(white: 1.0, alpha: 0.25)
        if songs.isEmpty {
            cell.textLabel?.text = "No music found"
            cell.detailTextLabel?.text = ""
            return cell
        }
        
        let song = songs[indexPath.row]

        cell.textLabel?.text = song.title
        cell.detailTextLabel?.text = song.artist
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            importFiles()
            return
        }
        guard !songs.isEmpty else {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }

        let song = songs[indexPath.row]
        let pathURL = DataHandler.documentsDirectory.appendingPathComponent("\(song.title!).caf")
        export(song: song, to: pathURL)
    }
    
    func export(song: MPMediaItem, to exportURL: URL) {
        let main = DispatchQueue.main
        SongExporter(exportPath: exportURL.path).exportSong(song) { (success) in
            guard success == true else {
                main.sync {
                    self.delegate?.dismissed(withURL: nil)
                }
                return
            }
            
            let tempo = TempoHandler.core.tempo(of: song.assetURL!, completion: nil)
            guard let bpm = tempo else {
                main.sync {
                    self.delegate?.dismissed(withURL: exportURL)
                }
                return
            }
            main.sync {
                self.delegate?.dismissed(withURL: exportURL, period: (60/bpm))
            }
        }
        drawerDismissClosure?()
    }
    
    func importFiles() {
        DispatchQueue.global(qos: .userInitiated).async {
            let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let handler = DataHandler()
            for file in self.files {
                guard let tempo = TempoHandler.core.tempo(of: docDir.appendingPathComponent(file), completion: nil) else { continue }
                handler.copyAsset(fromBundle: docDir.appendingPathComponent(file), toUserDomain: docDir.appendingPathComponent("files/\(file)"))
                handler.removeAsset(at: docDir.appendingPathComponent(file))
                self.delegate?.found(docDir.appendingPathComponent(file), period: tempo)
            }
        }
        drawerDismissClosure?()
    }
}

extension MusicDrawerController : DrawerConfiguration {
    func topPositionY(for parentHeight: CGFloat) -> CGFloat {
        guard isViewLoaded == true else { return 0 }
        let contentHeight = tableView.rect(forSection: 0).height
        guard parentHeight-(contentHeight+150) > 170 else {
            return 170
        }
        return parentHeight - (contentHeight + 150)
    }
    
    func middlePositionY(for parentHeight: CGFloat) -> CGFloat? {
        return nil
    }
    
    func bottomPositionY(for parentHeight: CGFloat) -> CGFloat {
        return parentHeight - 100
    }
    
    func setPanGestureTarget(_ target: Any, action: Selector) {
        panGestureTarget = target
        gestureRecognizer.addTarget(target, action: action)
    }
}

extension MusicDrawerController : UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let view = touch.view else { return true }
        if view.isDescendant(of: tableView) {
            return false
        }
        return true
    }
}

class FileFinder {
    let fileManager = FileManager.default
    let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
   
    func newFiles() -> [String]? {
        return try? fileManager.contentsOfDirectory(atPath: documentsDir.path).filter { $0.contains(".") && !$0.hasPrefix(".")}
    }
}

extension Array where Element: Hashable {
    func difference(from other: [Element]) -> [Element] {
        let thisSet = Set(self)
        let otherSet = Set(other)
        return Array(thisSet.symmetricDifference(otherSet))
    }
}
