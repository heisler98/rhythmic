//
//  NewMusicState.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 9/8/20.
//  Copyright © 2020 Hunter Eisler. All rights reserved.
//

import Combine
import MediaPlayer

class NewMusicState: ObservableObject {
    @Published var songs: [MPMediaItem]
    private var files: [String]
    let newTrack = PassthroughSubject<Track, Never>()
    let dismissInError = PassthroughSubject<Void, Never>()
    
    init() {
        let query = MPMediaQuery.songs()
        let predicate = MPMediaPropertyPredicate(value: false, forProperty: MPMediaItemPropertyIsCloudItem)
        query.addFilterPredicate(predicate)
        songs = []
        files = []
        guard let items = query.items else {
            return
        }
        for item in items where item.hasProtectedAsset == false {
            songs.append(item)
        }
        if let newFiles = FileFinder().newFiles() {
            files = newFiles
        }
    }
    
    func `import`(_ song: MPMediaItem) {
        let pathURL = DataHandler.documentsDirectory.appendingPathComponent("files/\(song.title!).caf")
        export(song: song, to: pathURL)
    }
    
    private func export(song: MPMediaItem, to url: URL) {
        let main = DispatchQueue.main
        SongExporter(exportPath: url.path).exportSong(song) { success in
            guard success == true else {
                return
            }
            let tempo = TempoHandler.core.tempo(of: song.assetURL!, completion: nil)
            guard let bpm = tempo else {
                self.dismissInError.send()
                return
            }
            main.sync { [self] in
                // create and add track
                newTrack.send(
                    track(at: url, tempo: bpm)
                )
            }
        }
    }
    
    func importFiles() {
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            let docDir = DataHandler.documentsDirectory
            let handler = DataHandler()
            for file in self.files {
                guard let tempo = TempoHandler.core.tempo(of: docDir.appendingPathComponent(file), completion: nil) else { continue }
                handler.copyAsset(fromBundle: docDir.appendingPathComponent(file), toUserDomain: docDir.appendingPathComponent("files/\(file)"))
                handler.removeAsset(at: docDir.appendingPathComponent(file))
                // tell somebody about that
                newTrack.send(
                    track(at: docDir.appendingPathComponent(file), tempo: tempo)
                )
            }
        }
    }
    
    func track(at url: URL, tempo: Double) -> Track {
        let lastComponent = url.pathComponents.last!
        let lastDot = lastComponent.lastIndex(of: ".") ?? lastComponent.endIndex
        let fileName = lastComponent[..<lastDot]
        
        return Track(title: String(fileName), period: 60/tempo, fileName: lastComponent)
    }
}
