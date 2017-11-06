//
//  algorithmTesterTests.swift
//  algorithmTesterTests
//
//  Created by Rumata on 11/5/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import XCTest
import algorithmTester

class SolutionTest: XCTestCase {
  static var allTests = [
    ("Sample Test Cases", testExample),
    ]

  func testExample() {
    var (code, input, solution) = (",+[-.,+]", "Codewars\(UnicodeScalar(255)!)", "Codewars")
    XCTAssertEqual(brainLuck(code, input: input), solution)
    (code, input) = (",[.[-],]","Codewars\(UnicodeScalar(0)!)" )
    XCTAssertEqual(brainLuck(code,input: input), solution)
    (code, input, solution) = (",>,<[>[->+>+<<]>>[-<<+>>]<<<-]>>.", "\(UnicodeScalar(8)!)\(UnicodeScalar(9)!)","\(UnicodeScalar(72)!)")
    XCTAssertEqual(brainLuck(code,input: input), solution)

  }
}

XCTMain([
  testCase(SolutionTest.allTests)
  ])

class algorithmTesterTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
