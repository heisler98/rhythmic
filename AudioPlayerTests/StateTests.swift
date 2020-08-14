//
//  StateTests.swift
//  AudioPlayerTests
//
//  Created by Hunter Eisler on 8/13/20.
//  Copyright © 2020 Hunter Eisler. All rights reserved.
//

import XCTest
@testable import AudioPlayer1

class StateTests: XCTestCase {

    var sut: AppState!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        sut = AppState()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        sut = nil
    }
    
    func testPlayback() throws {
        
    }

}
