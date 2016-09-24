//
//  ProtectedTests.swift
//  Deferred
//
//  Created by John Gallagher on 7/19/14.
//  Copyright © 2014-2015 Big Nerd Ranch. Licensed under MIT.
//

import XCTest
import Deferred

class ProtectedTests: XCTestCase {
    var protected: Protected<(Date?, [Int])>!
    var queue: DispatchQueue!

    override func setUp() {
        super.setUp()

        protected = Protected(initialValue: (nil, []))
        queue = DispatchQueue(label: "ProtectedTests", attributes: .concurrent)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testConcurrentReadingWriting() {
        var lastWriterDate: Date?

        let startReader: (Int) -> () = { i in
            let expectation = self.expectation(description: "reader \(i)")
            self.queue.async {
                self.protected.withReadLock { (date,items) -> () in
                    if items.count == 0 && date == nil {
                        // OK - we're before the writer has added items
                    } else if items.count == 5 && date == lastWriterDate {
                        // OK - we're after the writer has added items
                    } else {
                        XCTFail("invalid count (\(items.count)) or date (\(date))")
                    }
                }
                expectation.fulfill()
            }
        }

        for i in 0 ..< 64 {
            startReader(i)
        }
        let expectation = self.expectation(description: "writer")
        self.queue.async {
            self.protected.withWriteLock { dateItemsTuple -> () in
                for i in 0 ..< 5 {
                    dateItemsTuple.0 = Date()
                    dateItemsTuple.1.append(i)
                    timeIntervalSleep(0.1)
                }
                lastWriterDate = dateItemsTuple.0
            }
            expectation.fulfill()
        }
        for i in 64 ..< 128 {
            startReader(i)
        }

        waitForExpectationsShort()
    }

}