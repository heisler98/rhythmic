//
//  ViewModelTests.swift
//  AudioPlayerTests
//
//  Created by Hunter Eisler on 10/18/18.
//  Copyright © 2018 Hunter Eisler. All rights reserved.
//

import XCTest
@testable import AudioPlayer1

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
        let color = UIColor.swatch
        
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
        let handler = try? viewModel.sessionSelected(at: index)
        XCTAssertTrue(handler?.queue.queued == [0, 1, 2])
    }
    
    func testBuildTrack() {
        let url = URL(fileURLWithPath: "file:///Users/Hunter/Desktop/rhythmic m4a exports/Connection.m4a")
        let bpm = 147.000
        let title = "Connection"
        
        viewModel.buildTrack(url: url, periodOrBPM: bpm)
        let newTrack = viewModel.tracks[viewModel.tracks.tracks.endIndex-1]
        
        XCTAssertEqual(title, newTrack.title)
        XCTAssertEqual((1/(bpm/60)), newTrack.period)
        
    }
    
    func testBuildSession() {
        let indices = [0, 1, 2]
        let tracks = viewModel.tracks.tracks(forIndices: indices)
        viewModel.queue.append(all: indices)
        viewModel.buildSession(name: "A New Session")
        
        let newSession = viewModel.sessions[viewModel.sessions.sessions.endIndex-1]
        XCTAssertEqual(newSession.tracks, tracks)
        XCTAssertEqual(newSession.title, "A New Session")
    }
}
