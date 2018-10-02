//
//  TrackManagerTests.swift
//  AudioPlayerTests
//
//  Created by Hunter Eisler on 9/24/18.
//  Copyright © 2018 Hunter Eisler. All rights reserved.
//

import XCTest
@testable import AudioPlayer1

class TrackManagerTests: XCTestCase {

    var manager : TrackManager!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let handler = DataHandler()
        guard let tracks = try? handler.decodeJSONTracks() else {
            fatalError()
        }
        manager = TrackManager(tracks: tracks)
        
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        manager = nil
        super.tearDown()
    }

    func testTrackSubscriptAccess() {
        let aTrack = manager.tracks[0]
        let bTrack = manager![0]
        XCTAssertEqual(aTrack, bTrack)
    }
    
    func testTrackManagerCount() {
        var tracks = [Track]()
        do {
            tracks = try DataHandler().decodeJSONTracks()
        } catch {
            XCTFail("Cannot get JSON tracks: \(error)")
        }
        XCTAssertEqual(tracks.count, manager.count)
    }
    
    func testAppendTrack() {
        let newTrack = Track(title: "HelloWorld", period: 0.5, fileName: "helloworld.mp3")
        manager.append(track: newTrack)
        XCTAssertEqual(newTrack, manager.tracks.last!)
    }
    
    func testRemoveTrack() {
        let track = manager.remove(at: manager.tracks.endIndex-1)
        XCTAssertFalse(manager.tracks.contains(track))
    }
/*
    func testPref() {
        XCTAssertTrue(UserDefaults.standard.double(forKey: "slider_crosspan") == 0.87)
    }
 */
}

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

class QueueHandlerTests : XCTestCase {
    
    var queue : QueueHandler!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.

        let indices = randsInRange(range: 0..<50, quantity: 10)
        queue = QueueHandler(queued: indices)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        queue = nil
        
        super.tearDown()
    }
    
    func testAdvancePosition() {
        let currentPosition = queue.position
        let nextIndex = queue.next()
        
        XCTAssertEqual(queue[currentPosition+1], nextIndex)
    }
    
    func testReset() {
        let zerothIndex = queue[0]
        queue.reset()
        let resetIndex = queue[queue.position]
        XCTAssertEqual(zerothIndex, resetIndex)
    }
    
    func testPositionAccess() {
        let anIndex = queue[2]
        let indexPosition = queue.position(of: anIndex)
        XCTAssertEqual(2, indexPosition)
    }
    
    func test_PositionAfterAccess() {
        let anIndex = queue[queue.position]
        let afterIndex = queue[queue.position+1]
        let afterPosition = queue.position(after: anIndex)
        XCTAssertEqual(afterIndex, queue[afterPosition])
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
            playback = try PlaybackHandler(queue: queue)
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
        XCTAssertFalse(playback.isPlaying)
        playback.pauseResume()
        XCTAssertTrue(playback.isPlaying)
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
        playback.previous()
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

class ViewModelTests : XCTestCase {
    var viewModel : ViewModel!

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        try? DataHandler().encodeTracks(DataHandler().defaultTracks())
        viewModel = ViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDetailString() {
        viewModel.tracks[5].rhythm = .Crosspan
        viewModel.tracks[5].rate = .Normal
        let period = viewModel.tracks[5].period
        let perStr = String(format: "%.3f", period)
        let detString = viewModel.detailString(for: 5)
        let testString = "Crosspan : 1x : \(perStr)"
        XCTAssertEqual(detString, testString)
    }
    
    func testPlaybackHandler_ThrowsError() {
        XCTAssertThrowsError(try viewModel.playbackHandler())
    }
    
    func testPlaybackHandler_Returns() {
        let indices = [1, 3, 4, 7, 10]
        viewModel.queue.append(all: indices)
        XCTAssertNoThrow(try viewModel.playbackHandler())
    }

    func testSetupCell() {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        viewModel.queue.append(selected: 0)
        viewModel.setupCell(cell, forIndexPath: IndexPath(row: 0, section: 1))
        
        let title = viewModel.tracks[0].title
        let detailText = viewModel.detailString(for: 0)
        let color = UIColor(red: 1, green: 0.4, blue: 0.4, alpha: 1.0)
        
        XCTAssertEqual(title, cell.textLabel!.text!)
        XCTAssertEqual(detailText, cell.detailTextLabel!.text!)
        XCTAssertTrue(cell.accessoryType == .checkmark)
        XCTAssertEqual(color, cell.tintColor)
        XCTAssertEqual(color, cell.textLabel!.textColor)
    }

    func testSelectSession() {
        let someTracks = Array(viewModel.tracks.tracks[0..<3])
        let session = Session(tracks: someTracks, title: "First 3")
        viewModel.sessions.add(session)
        
        guard let index = viewModel.sessions.sessions.firstIndex(of: session) else { XCTFail(); return }
        let handler = try! viewModel.sessionSelected(at: index)
        XCTAssertTrue(handler.queue.queued == [0, 1, 2])
    }
}

class QueueTests : XCTestCase {
    
    var viewModel : ViewModel!
    var queue : Queue!
    
    override func setUp() {
        super.setUp()
        viewModel = ViewModel()
        queue = viewModel.queue
    }
    
    override func tearDown() {
        viewModel = nil
        queue = nil
        super.tearDown()
    }
    
    func testSequence_Iterator() {
        let indices = [1, 3, 4, 7, 10]
        queue.append(all: indices)
        
        var counter = 0
        for i in queue {
            XCTAssertEqual(indices[counter], i)
            counter += 1
        }
    }
    
    func testAppend() {
        queue.append(selected: 10)
        XCTAssertEqual(10, queue![0])
    }
    
    func testRemove() {
        queue.append(selected: 10)
        XCTAssertNotNil(queue.remove(selected: 10))
    }
    
    func testRemoveAll() {
        queue.append(all: [1,3,])
    }
    
    func testContains() {
        let indices = [1, 3, 4, 7, 10]
        queue.append(all: indices)
        XCTAssertTrue(queue.contains(3))
    }
    
    func testCellSelected() {
        queue.cellSelected(at: 10)
        XCTAssertTrue(queue.contains(10))
    }
    
    func testSafeSelectCell() {
        queue.cellSelected(at: 10)
        queue.safeSelectCell(at: 10)
        XCTAssertTrue(queue.contains(10))
    }
}

class SessionManagerTests : XCTestCase {
    var manager : SessionManager!
    var tracks : TrackManager!
    
    override func setUp() {
        super.setUp()
        try? DataHandler().encodeTracks(DataHandler().defaultTracks())
        manager = SessionManager()
        tracks = TrackManager()
    }
    
    override func tearDown() {
        manager = nil
        tracks = nil
        super.tearDown()
    }
    
    func testAddSession() {
        let someTracks = Array(tracks.tracks[0..<3])
        let session = Session(tracks: someTracks, title: "First 4")
        manager.add(session)
       
        let aSession = manager[manager.sessions.count-1]
        XCTAssertTrue(aSession == session)
    }
    
    func testTracksInSession() {
        let someTracks = Array(tracks.tracks[3..<7])
        let session = Session(tracks: someTracks, title: "3 thru 6")
        manager.add(session)
        
        let aSession = manager[manager.sessions.count-1]
        XCTAssertTrue(aSession.tracks == someTracks)
    }
}
