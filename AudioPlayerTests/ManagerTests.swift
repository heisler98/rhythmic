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
        manager = TrackManager(tracks: handler.defaultTracks())
        
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
        tracks = DataHandler().defaultTracks()
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
    
    func testFindingIndices() {
        let indices = [0, 1, 2]
        let tracks = [manager[0], manager[1], manager[2]]
        
        let managersTracks = manager.tracks(forIndices: indices)
        
        XCTAssertEqual(tracks, managersTracks)
    }
/*
    func testPref() {
        XCTAssertTrue(UserDefaults.standard.double(forKey: "slider_crosspan") == 0.87)
    }
 */
}

class SessionManagerTests : XCTestCase {
    var manager : SessionManager!
    var tracks : TrackManager!
    
    override func setUp() {
        super.setUp()
        try? DataHandler().encodeTracks(DataHandler().defaultTracks())
        manager = SessionManager()
        tracks = TrackManager()
        
        let someTracks = Array(tracks.tracks[0..<5])
        let session = Session(tracks: someTracks, title: "First 6")
        manager.add(session)
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
    
    func testRemoveSession() {
        let session = manager[0]
        let removedSession = manager.delete(session: 0)
        XCTAssertEqual(session, removedSession!)
        XCTAssertFalse(manager.sessions.contains(session))
        
    }
    
    func testRemoveTrackFromSession_ByLiteral() {
        let someTracks = Array(tracks.tracks[2..<5])
        let session = Session(tracks: someTracks, title: "Mutable")
        manager.add(session)
        
        let trackToRemove = tracks[3]
        let removedTrack = manager.removeTrack(trackToRemove, fromSession: manager.sessions.count-1)
        XCTAssertEqual(trackToRemove, removedTrack!)
        XCTAssertFalse(manager.sessions[manager.sessions.endIndex-1].tracks.contains(trackToRemove))
    }
    
    func testRemoveTrackFromSession_ByIndex() {
        let someTracks = Array(tracks.tracks[3..<5])
        let session = Session(tracks: someTracks, title: "Mutable")
        manager.add(session)
        
        let indexOfTrackInTracks = 4
        let indexOfTrackInSession = 1
        
        let removedTrack = manager.removeTrack(at: indexOfTrackInSession, fromSession: manager.sessions.endIndex-1)
        
        XCTAssertEqual(removedTrack!, tracks[indexOfTrackInTracks])
        XCTAssertFalse(manager.sessions[manager.sessions.endIndex-1].tracks.contains(tracks[indexOfTrackInTracks]))
        
    }
    
    func testTracksInSession() {
        let someTracks = Array(tracks.tracks[3..<5])
        let session = Session(tracks: someTracks, title: "3 thru 6")
        manager.add(session)
        
        let aSession = manager[manager.sessions.count-1]
        XCTAssertTrue(aSession.tracks == someTracks)
    }
    
    func testSessionResponder_RemoveTrack() {
        let delegater = MockSessionDelegater()
        delegater.delegate = manager
        
        let trackToRemove = manager[0].tracks[0]
        delegater.willRemoveTrack(atIndex: 0, from: 0)
        XCTAssertFalse(manager[0].tracks.contains(trackToRemove))
    }
    
    func testSessionResponder_MoveTrack() {
        let delegater = MockSessionDelegater()
        delegater.delegate = manager
        
        let trackToMove = manager[0].tracks[0] // move to 1
        
        delegater.willMoveTrack(from: 0, to: 1, in: 0)
        
        XCTAssertTrue(manager.tracks(inSession: 0).firstIndex(of: trackToMove)! == 1)
    }
}

class MockSessionDelegater {
    var delegate : SessionResponder?
    func willRemoveTrack(atIndex index: Index, from sessionIndex: Index) {
        delegate?.trackRemoved(at: index, from: sessionIndex)
    }
    func willMoveTrack(from oldIndex: Index, to newIndex: Index, in sessionIndex: Index) {
        delegate?.trackMoved(from: oldIndex, to: newIndex, in: sessionIndex)
    }
}
