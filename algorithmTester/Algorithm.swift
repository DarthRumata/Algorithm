//
//  Algorithm.swift
//  algorithmTester
//
//  Created by Rumata on 11/1/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import Foundation

enum Command: String {
  case moveForward = ">"
  case moveBackward = "<"
  case increaseValue = "+"
  case decreaseValue = "-"
  case readValue = ","
  case writeValue = "."
  case startLoop = "["
  case endLoop = "]"
}

func parse(code: String) -> [Command] {
  return code.characters.map { Command(rawValue: String($0))! }
}

var memoryCount = 1
var memoryPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: memoryCount)
var currentMemoryPosition = 0
var outputSequence: [UnicodeScalar] = []
var inputSequence: [UInt8]!
var loopPointers = [Int]()
var commandPointer = 0

func brainLuck(_ code: String, input: String) -> String {
  defer {
    cleanUp()
  }

  inputSequence = input.characters.map { UInt8(String($0).unicodeScalars.first!.value) }.reversed()
  let commandSequence = parse(code: code)
  execute(sequence: commandSequence)
  return outputSequence.reduce("") { (result, current) -> String in
    return "\(result)\(current.escaped(asASCII: true))"
  }
}

func cleanUp() {
  currentMemoryPosition = 0
  memoryPointer.initialize(to: 0, count: memoryCount)
  memoryCount = 1
  outputSequence.removeAll()
  loopPointers.removeAll()
  commandPointer = 0
}

func execute(sequence: [Command]) {
  while (commandPointer < sequence.count) {
    let command = sequence[commandPointer]
    if execute(command: command) {
      commandPointer += 1
    }
  }
}

func execute(command: Command) -> Bool {
  switch command {
  case .moveForward:
    currentMemoryPosition += 1
    if currentMemoryPosition >= memoryCount {
      memoryCount = currentMemoryPosition + 1
    }

  case .moveBackward:
    currentMemoryPosition -= 1

  case .increaseValue:
    let value = memoryPointer[currentMemoryPosition]
    memoryPointer[currentMemoryPosition] = value &+ 1

  case .decreaseValue:
    let value = memoryPointer[currentMemoryPosition]
    memoryPointer[currentMemoryPosition] = value &- 1

  case .readValue:
    let inputScalar = inputSequence.popLast()!
    memoryPointer[currentMemoryPosition] = inputScalar

  case .writeValue:
    outputSequence.append(UnicodeScalar(memoryPointer[currentMemoryPosition]))

  case .startLoop:
    if memoryPointer[currentMemoryPosition] != 0 {
      loopPointers.append(commandPointer)
    }

  case .endLoop:
    let loopPointer = loopPointers.popLast()!
    if memoryPointer[currentMemoryPosition] != 0 {
      commandPointer = loopPointer
      return false
    }
  }
  
  return true
}


