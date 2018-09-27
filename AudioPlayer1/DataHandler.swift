//
//  DataHandler.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 9/24/18.
//  Copyright © 2018 Hunter Eisler. All rights reserved.
//

import Foundation

public struct DataHandler {
    
    static let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    static let archiveURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("tracks")
    
    func decodeJSONData() throws -> [Track] {
        do {
            let data = try getData()
            return try JSONDecoder().decode(TrackArray.self, from: data)
        } catch {
            throw error
        }
        
    }
    
    func encodeTracks(_ tracks : [Track]) throws {
        do {
            let data = try JSONEncoder().encode(tracks)
            FileManager.default.createFile(atPath: DataHandler.archiveURL.path, contents: data, attributes: nil)
        } catch {
            throw error
        }
    }
    
    func defaultTracks() -> [Track] {
        
        guard let plistUrl = Bundle.main.url(forResource: "Tracks", withExtension: "plist") else { fatalError() }
        guard let data = try? Data(contentsOf: plistUrl)  else { fatalError() }
        
        let plistArray = serializePLIST(fromData: data)
        
        return tracks(fromSerialized: plistArray)
    }
    
    private func copyAsset(fromBundle bundleURL : URL, toUserDomain trackURL : URL) {
        
        do {
            try FileManager.default.copyItem(at: bundleURL, to: trackURL)
        } catch {
            print(error)
        }
    }
    
    private func tracks(fromSerialized serial: [Dictionary<String, String>]) -> [Track] {
        var tracks = [Track]()
        
        for aDict in serial {
            let file = aDict["title"]! + "." + aDict["extension"]!
            let track = Track(title: aDict["title"]!, period: Double(aDict["period"]!)!, fileName: file)
            tracks.append(track)
            
            let bundleURL = Bundle.main.url(forResource: aDict["title"]!, withExtension: aDict["extension"]!)
            copyAsset(fromBundle: bundleURL!, toUserDomain: track.url)
        }
        return tracks
    }
    
    private func serializePLIST(fromData data : Data) -> [Dictionary<String, String>] {
        var tracks : [Dictionary<String, String>]?
        
        do {
            tracks = try PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil) as? [Dictionary<String, String>]
        } catch {
            print(error)
        }
        guard tracks != nil else { fatalError() }
        return tracks!
    }
    
    private func getData() throws -> Data {
        guard let data = FileManager.default.contents(atPath: DataHandler.archiveURL.path) else {
            
            let error = NSError(domain: "DataHandlerFileManagerContents", code: 1, userInfo: nil)
            throw error
        }
        return data
    }
}
