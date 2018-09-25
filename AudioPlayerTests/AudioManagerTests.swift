//
//  AudioPlayerTests.swift
//  AudioPlayerTests
//
//  Created by Hunter Eisler on 9/15/18.
//  Copyright © 2018 Hunter Eisler. All rights reserved.
//

import XCTest
@testable import AudioPlayer1

class AudioManagerTests: XCTestCase {
    
    var audioManager : AudioManager!
    var range : Range<Int>!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        audioManager = AudioManager.shared
        range = 0..<audioManager.trackCount
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        audioManager = nil
        range = nil
        super.tearDown()
        
    }
    
    func testJSONArchiveFileAccessible() {
        let data = FileManager.default.contents(atPath: AudioManager.archiveURL.path)
        XCTAssertNotNil(data)
    }
    
    func testJSONTrackCount_MatchesAudioManagerCount() {
        guard let data = FileManager.default.contents(atPath: AudioManager.archiveURL.path) else { XCTFail("Cannot retrieve data at archive path"); return }
        var jsonTracks : [Track] = TrackArray()
        
        do {
            jsonTracks = try JSONDecoder().decode(TrackArray.self, from: data)
        } catch {
            XCTFail("Cannot decode JSON data: \(error)")
        }
        XCTAssertEqual(jsonTracks.count, audioManager.trackCount)
    }
    
    func testRateChange_isSaved() {
        let index = randsInRange(range: range, quantity: 1)
        
        audioManager.setRate(.Quad, forIndex: index[0])
        
        XCTAssertEqual(audioManager.rate(forIndex: index[0]), PanRate.Quad)
    }
    
    func testRhythmChange_isSaved() {
        let index = randsInRange(range: range, quantity: 1)
        
        _ = audioManager.setRhythm(.Stitch, forIndex: index[0])
        
        XCTAssertEqual(audioManager.rhythm(forIndex: index[0]), Rhythmic.Stitch)
    }
    
    func testTrackIsDeleted() {
        let index = randsInRange(range: range, quantity: 1)[0]
        let deleted = audioManager.tracks[index]
        
        _ = audioManager.deleteTrack(atIndex: index)
        
        XCTAssertFalse((AudioManager.loadTracks()?.contains(deleted))!)
    }
    
    func testPlaybackIsSuccessful() {
        let selected = randsInRange(range: range, quantity: 7)
        XCTAssertTrue(audioManager.playback(queued: selected))
        XCTAssertTrue(audioManager.isPlaying)
    }
    
    func testInstantiatePlayersIsSuccessful() {
        audioManager.playIndices = randsInRange(range: range, quantity: 7)
        XCTAssertTrue(audioManager.instantiatePlayers())
    }
    
    func testPerformance_FullPlayback() {
        let selected = randsInRange(range: range, quantity: 7)
        self.measure {
            _ = audioManager.playback(queued: selected)
        }
    }
    
    func testPerformance_InstantiatePlayers() {
        audioManager.playIndices = randsInRange(range: range, quantity: 7)
        self.measure {
            _ = audioManager.instantiatePlayers()
        }
    }

    func testStopPlayback() {
        let selected = randsInRange(range: range, quantity: 1)
        _ = audioManager.playback(queued: selected)
        audioManager.stopPlayback()
        
        XCTAssertFalse(audioManager.isPlaying)
    }
    
    func testPlaybackPause() {
        let selected = randsInRange(range: range, quantity: 1)
        _ = audioManager.playback(queued: selected)
        
        XCTAssertTrue(audioManager.isPlaying, "Player is playing")
        audioManager.togglePauseResume()
        XCTAssertFalse(audioManager.isPlaying)
        audioManager.togglePauseResume()
        XCTAssertTrue(audioManager.isPlaying, "Player has resumed")
    }
    
    func testAddTrack() {
        let newTrack = Track(title: "Test Track", period: 0.555, category: "song", fileName: "testtrack.mp3", rhythm: .Bilateral, rate: .Normal)
        audioManager.add(newTrack: newTrack)
        
        guard let tracks = AudioManager.loadTracks() else { XCTFail("Cannot load tracks"); fatalError() }
        
        XCTAssertTrue(tracks.contains(newTrack))
        
        guard let index = tracks.index(of: newTrack) else { fatalError() }
        _ = audioManager.deleteTrack(atIndex: index)
    }
    
    func testDeleteTrack() {
        let index = randsInRange(range: range, quantity: 1)[0]
        let countBefore = audioManager.trackCount
        
        XCTAssertTrue(audioManager.deleteTrack(atIndex: index), "Delete track at specified index")
        
        let countAfter = audioManager.trackCount
        
        XCTAssertEqual(countBefore, countAfter + 1)
    }
    
    func testRepeatQueue() {
        let selected = randsInRange(range: range, quantity: 1)
        
        _ = audioManager.playback(queued: selected)
        audioManager.skipCurrentTrack()
        
        XCTAssertTrue(audioManager.isPlaying, "Player is not playing after track skip")
    }
    
    func testPerformance_RepeatQueue() {
        let selected = randsInRange(range: range, quantity: 1)
        _ = audioManager.playback(queued: selected)
        self.measure {
            audioManager.skipCurrentTrack()
        }
    }
}
