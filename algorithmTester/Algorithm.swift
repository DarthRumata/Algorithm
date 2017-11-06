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

var counter = 0

func parse(code: String) -> [Command] {
  return code.characters.map { Command(rawValue: String($0))! }
}

var memory = [Double: UInt8]()
var memoryPointer: Double = 0
var outputSequence: [UnicodeScalar] = []
var inputSequence: [UInt8]!
var loopPointers = [Int]()
var commandPointer = 0
var topIndex: Double = 0
var bottomIndex: Double = 0

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

func createCell() {
  memory[memoryPointer] = 0
}

func cleanUp() {
  topIndex = 0
  bottomIndex = 0
  memoryPointer = 0
  memory.removeAll()
  memory[0] = 0
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
    memoryPointer += 1
    if memoryPointer > topIndex {
      createCell()
      topIndex = memoryPointer
    }

  case .moveBackward:
    memoryPointer -= 1
    if memoryPointer < bottomIndex {
      createCell()
      bottomIndex = memoryPointer
    }

  case .increaseValue:
    let value = memory[memoryPointer]!
    memory[memoryPointer] = value &+ 1

  case .decreaseValue:
    let value = memory[memoryPointer]!
    memory[memoryPointer] = value &- 1

  case .readValue:
    let inputScalar = inputSequence.popLast()!
    memory[memoryPointer] = inputScalar

  case .writeValue:
    outputSequence.append(UnicodeScalar(memory[memoryPointer]!))

  case .startLoop:
    if memory[memoryPointer]! != 0 {
      loopPointers.append(commandPointer)
    }

  case .endLoop:
    let loopPointer = loopPointers.popLast()!
    if memory[memoryPointer]! != 0 {
      commandPointer = loopPointer
      return false
    }
  }
  
  return true
}


