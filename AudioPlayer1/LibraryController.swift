//
//  LibraryController.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 4/14/18.
//  Copyright © 2018 Hunter Eisler. All rights reserved.
//

import UIKit
import MediaPlayer

protocol iTunesDelegate {
    func dismissed(withURL : URL?)
}

class LibraryController: UITableViewController {
    
    var delegate : iTunesDelegate?
    var songs = [MPMediaItem]()
    
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "songCell", for: indexPath)
        
        if songs.count == 0 {
            cell.textLabel?.text = "Tap 'Load'"
            return cell
        }
        
        let songItem = songs[indexPath.row]
        guard let title = songItem.title else { return cell }
        
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = songItem.artist

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let song = songs[indexPath.row]
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        guard let directory = paths.first else { print("no path found"); delegate?.dismissed(withURL: nil); return }
        let pathURL = directory.appendingPathComponent("\(song.title!).caf")
        
        let exporter = SongExporter(exportPath: pathURL.path)
        exporter.exportSong(song) { (success) in
            if success == true {
                DispatchQueue.main.sync {
                    self.delegate?.dismissed(withURL: pathURL)
                }
            } else {
                DispatchQueue.main.sync {
                    print("SongExporter failed")
                    self.delegate?.dismissed(withURL: nil)
                }
            }
        }
    }
    
    @IBAction func cancel(_ sender : Any) {
        delegate?.dismissed(withURL: nil)
    }

}
