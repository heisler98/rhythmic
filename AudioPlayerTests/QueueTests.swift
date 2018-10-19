//
//  QueueTests.swift
//  AudioPlayerTests
//
//  Created by Hunter Eisler on 10/18/18.
//  Copyright © 2018 Hunter Eisler. All rights reserved.
//

import XCTest
@testable import AudioPlayer1

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
