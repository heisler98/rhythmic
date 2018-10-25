//
//  LibraryController.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 4/14/18.
//  Copyright © 2018 Hunter Eisler. All rights reserved.
//

import UIKit
import MediaPlayer
import CoreGraphics

protocol iTunesDelegate : AnyObject {
    func dismissed(withURL : URL?)
    func dismissed(withURL: URL, period: Double)
}

class LibraryController: UITableViewController {
    
    var delegate : iTunesDelegate?
    var songs = [MPMediaItem]()
    
    @IBOutlet var gestureRecognizer: UIPanGestureRecognizer!
    var drawerDismissClosure: (() -> Void)?
    var didChangeLayoutClosure: (() -> Void)?
    var panGestureTarget: Any?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let query = MPMediaQuery.songs()
        let predicate = MPMediaPropertyPredicate(value: false, forProperty: MPMediaItemPropertyIsCloudItem)
        query.addFilterPredicate(predicate)
        guard let items = query.items else { return }
        
        for item in items where item.hasProtectedAsset == false {
            songs.append(item)
        }
        
        tableView.reloadData()
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        didChangeLayoutClosure?()
    }

    @IBAction func load(_ sender : Any) {
        
        let query = MPMediaQuery.songs()
        let predicate = MPMediaPropertyPredicate(value: false, forProperty: MPMediaItemPropertyIsCloudItem)
        query.addFilterPredicate(predicate)
        guard let items = query.items else { return }
        
        songs.removeAll()
        for item in items where item.hasProtectedAsset == false {
            songs.append(item)
        }
        
        tableView.reloadData()
    }
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if songs.count == 0 {
            return 1
        }
        return songs.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.Library.rawValue, for: indexPath)
        
        if songs.count == 0 {
            cell.textLabel?.text = "No songs found"
            cell.detailTextLabel?.text = "Tap 'Reload'"
            return cell
        }
        
        let songItem = songs[indexPath.row]
        guard let title = songItem.title else { return cell }
        
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = songItem.artist

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard songs.count > 0 else {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        let main = DispatchQueue.main
        
        let activityView = UIActivityIndicatorView(style: .whiteLarge)
        activityView.center = view.center
        activityView.layer.backgroundColor = UIColor(white: 0.0, alpha: 0.35).cgColor
        activityView.hidesWhenStopped = true
        view.insertSubview(activityView, aboveSubview: tableView)
        let song = songs[indexPath.row]
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        guard let directory = paths.first else { print("no path found"); delegate?.dismissed(withURL: nil); return }
        let pathURL = directory.appendingPathComponent("\(song.title!).caf")
        
        SongExporter(exportPath: pathURL.path).exportSong(song) { (success) in
            if success == true {
                main.sync {
                    activityView.startAnimating()
                }
                let tempo = TempoHandler.core.tempo(of: song.assetURL!, completion: { _ in
                    //stop activityviewindicator
                    main.sync {
                        activityView.stopAnimating()
                    }
                })
                main.sync {
                    guard let bpm = tempo else { self.delegate?.dismissed(withURL: pathURL); return }
                    self.delegate?.dismissed(withURL: pathURL, period: (1/(bpm/60)))
                }
            } else {
                main.sync {
                    self.delegate?.dismissed(withURL: nil)
                }
            }
        }
        drawerDismissClosure?()
    }
    
    @IBAction func cancel(_ sender : Any) {
        delegate?.dismissed(withURL: nil)
        drawerDismissClosure?()
    }

}

extension LibraryController : DrawerConfiguration {
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
        guard isViewLoaded == true else { return 0 }
        let contentHeight = tableView.rect(forSection: 0).height
        guard parentHeight-(contentHeight+150) > 170 else {
            return 170
        }
        return parentHeight - (contentHeight + 150)
    }
    
    func setPanGestureTarget(_ target: Any, action: Selector) {
        panGestureTarget = target
        gestureRecognizer.addTarget(target, action: action)
    }
}

extension LibraryController : UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let view = touch.view else { return true }
        if (view is UINavigationBar) {
            return true
        }
        return false
    }
 
    
}
