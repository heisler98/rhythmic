//
//  PannerTests.swift
//  RhythmicTests
//
//  Created by Hunter Eisler on 8/11/20.
//

import XCTest
import FileKit
@testable import Rhythmic
class PannerTests: XCTestCase {
    
    var sut: Panner!
    var player: MockPlayer!
    var secondPlayer: MockPlayer!
    
    override func setUpWithError() throws {
        sut = Panner()
        player = MockPlayer()
        secondPlayer = MockPlayer()
    }
    
    override func tearDownWithError() throws {
        sut = nil
    }
    
    func testPan() throws {
        let expectation = XCTestExpectation()
        sut.start(player, 0.500)
        // Keep name; otherwise the publisher never sinks.
        let anyCancellable = player.panChanged
            .dropFirst(2)
            .sink {
                expectation.fulfill()
            }
        wait(for: [expectation], timeout: 5)
    }
    
    func testSecondPlayer() throws {
        let expectation = XCTestExpectation()
        sut.start(player, 0.250)
        
        sut.start(secondPlayer, 0.250)
        // Keep name; otherwise the publisher never sinks.
        let anyCancellable = secondPlayer.panChanged
            .dropFirst(2)
            .sink {
                expectation.fulfill()
            }
        wait(for: [expectation], timeout: 5)
    }

}

import Combine
class MockPlayer: Pannable {
    var pan: Float = 1.0 {
        didSet {
            panChanged.send()
        }
    }
    
    var panChanged = PassthroughSubject<Void, Never>()
    
    func prepareToPlay() -> Bool {
        true
    }
    
    func play() -> Bool {
        true
    }
}
