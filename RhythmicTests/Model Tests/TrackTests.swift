//
//  TrackTests.swift
//  RhythmicTests
//
//  Created by Hunter Eisler on 8/11/20.
//

import XCTest
import FileKit
@testable import Rhythmic

class TrackTests: XCTestCase {
    
    var sut: Track!
    
    override func setUpWithError() throws {
        sut = Track(title: "Let's Hurt Tonight",
                    period: 0.500,
                    path: (Path.userDocuments +
                            "Let's Hurt Tonight.mp3").standardRawValue)
    }
    
    override func tearDownWithError() throws {
        sut = nil
    }
}
