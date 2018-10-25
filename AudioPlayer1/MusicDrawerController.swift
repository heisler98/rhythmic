//
//  MusicDrawerController.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 10/25/18.
//  Copyright © 2018 Hunter Eisler. All rights reserved.
//

import UIKit
import MediaPlayer

class MusicDrawerController: UIViewController {

    @IBOutlet var gestureRecognizer: UIPanGestureRecognizer!
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var label: UILabel!
    
    weak var delegate : iTunesDelegate?
    var songs = [MPMediaItem]()
    
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
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if songs.isEmpty {
            return 1
        }
        return songs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
                self.delegate?.dismissed(withURL: exportURL)
                return
            }
            self.delegate?.dismissed(withURL: exportURL, period: (1/(bpm/60)))
            
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
