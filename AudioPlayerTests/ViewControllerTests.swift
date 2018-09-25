//
//  ViewControllerTests.swift
//  AudioPlayerTests
//
//  Created by Hunter Eisler on 9/24/18.
//  Copyright © 2018 Hunter Eisler. All rights reserved.
//

import XCTest
@testable import AudioPlayer1

class ViewControllerTests: XCTestCase {

    var viewController : ViewController!
    var audioManager : AudioManager!
    var range : Range<Int>!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        viewController = UIStoryboard(name: "Main", bundle: Bundle(identifier: "com.eisler.AudioPlayer1")).instantiateViewController(withIdentifier: "rhythmicController") as? ViewController
        audioManager = AudioManager.shared
        range = 0..<audioManager.trackCount
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        viewController = nil
        range = nil
        audioManager = nil
        
        super.tearDown()
    }

}
