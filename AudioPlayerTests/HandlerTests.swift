//
//  DataHandlerTests.swift
//  AudioPlayerTests
//
//  Created by Hunter Eisler on 10/18/18.
//  Copyright © 2018 Hunter Eisler. All rights reserved.
//

import XCTest
@testable import AudioPlayer1

class DataHandlerTests : XCTestCase {
    var mockHandler : MockJSONRead!
    
    override func setUp() {
        super.setUp()
        // set up here
    }
    
    override func tearDown() {
        //Tear down here
        
        super.tearDown()
    }
    
    func testArchiveURL() {
        XCTAssertEqual(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("tracks"), DataHandler.tracksArchiveURL)
    }
    
    func testEncodeTracks() {
        let aTrack = Track(title: "Hello World", period: 0.5, fileName: "HelloWorld.mp3")
        let tracks = [aTrack]
        
        do {
            try DataHandler().encodeTracks(tracks)
        } catch {
            XCTFail("Encoding threw exception: \(error)")
        }
        
        var decoded = [Track]()
        do {
            decoded = try DataHandler().decodeJSONTracks()
        } catch {
            XCTFail("Decoding threw exception: \(error)")
        }
        
        XCTAssertEqual(tracks, decoded)
    }
    
    func testDecodeTracks() {
        mockHandler = DataHandler()
        let array = mockHandler.mockDecodeJSON()
        for track in array {
            XCTAssertTrue(track.rate.rawValue < 4)
            XCTAssertTrue(track.rhythm.rawValue < 4)
            XCTAssertTrue(track.title != "")
            XCTAssertTrue(track.period > 0)
        }
    }
    
}

protocol MockJSONRead {
    func mockDecodeJSON() -> TrackArray
}

extension DataHandler : MockJSONRead {
    func mockDecodeJSON() -> TrackArray {
        let assetURL = Bundle.main.url(forResource: "tracks_test", withExtension: nil)
        let data : Data
        do {
            data = try Data(contentsOf: assetURL!)
            return try JSONDecoder().decode(TrackArray.self, from: data)
        } catch {
            print(error)
            fatalError()
        }
    }
}

class PlaybackHandlerTests : XCTestCase {
    
    var playback : PlaybackHandler!
    var indices : [Index]!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        indices = randsInRange(range: 0..<30, quantity: 10)
        let queue = ViewModel().queue
        queue.append(all: indices)
        try? DataHandler().encodeTracks(DataHandler().defaultTracks())
        do {
            playback = try PlaybackHandler(queue: queue, start: false)
        } catch {
            fatalError()
        }
        
    }
    
    override func tearDown() {
        if playback.isPlaying { playback.stopPlaying() }
        playback = nil
        
        indices = nil
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testIsPlaying() {
        playback.startPlaying()
        XCTAssertTrue(playback.isPlaying)
    }
    
    func testStopPlaying() {
        playback.startPlaying()
        XCTAssertTrue(playback.isPlaying)
        playback.stopPlaying()
        XCTAssertFalse(playback.isPlaying)
        
    }
    
    func testPauseResume() {
        playback.startPlaying()
        XCTAssertTrue(playback.isPlaying)
        playback.pauseResume()
        XCTAssertTrue(playback.isPaused)
        playback.pauseResume()
        XCTAssertFalse(playback.isPaused)
    }
    
    func testSkip() {
        playback.startPlaying()
        //position = 0
        playback.skip()
        //position = 1
        XCTAssertTrue(playback.queue.position == 1)
        XCTAssertTrue(playback.isPlaying)
    }
    
    func testPrevious() {
        playback.startPlaying()
        //position = 0
        playback.rewind()
        //position = endIndex-1
        XCTAssertTrue(playback.queue.position == playback.queue.queued.endIndex-1)
        XCTAssertTrue(playback.isPlaying)
    }
    
    func testSeek() {
        playback.startPlaying()
        //position = 0
        playback.seek(to: 30)
        guard let player = playback.tracks.tracks[playback.queue.now].audioPlayer else {
            XCTFail("Cannot load track audio player"); return
        }
        XCTAssertTrue(player.currentTime >= 30)
    }
    
    func testSkipBackward() {
        playback.startPlaying()
        let player = playback.tracks[playback.queue.now].audioPlayer!
        player.currentTime = 30
        playback.seekBackward(10)
        XCTAssertTrue(player.currentTime >= 20 && player.currentTime < 30)
    }
    
    func testSeekForward() {
        playback.startPlaying()
        let player = playback.tracks[playback.queue.now].audioPlayer!
        let timeA = player.currentTime
        playback.seekForward(5)
        let timeB = player.currentTime
        playback.seekForward(5)
        let timeC = player.currentTime
        
        XCTAssertTrue(Int(timeB - timeA) == 5)
        //XCTAssertTrue(Int(timeC - timeB) == 5)
        XCTAssertEqual(Int(timeC-timeB), 5)
        
        // test auto-skip
        let positionA = playback.queue.position
        player.currentTime = player.duration-2
        playback.seekForward(5)
        XCTAssertEqual(positionA+1, playback.queue.position)
    }
    
    
}
