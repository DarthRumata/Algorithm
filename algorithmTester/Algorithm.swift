//
//  Algorithm.swift
//  algorithmTester
//
//  Created by Rumata on 11/1/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import Foundation

enum AtomicCommand: String {
  case moveForward = ">"
  case moveBackward = "<"
  case increaseValue = "+"
  case decreaseValue = "-"
  case readValue = ","
  case writeValue = "."
  case startLoop = "["
  case endLoop = "]"
}

struct MetaCommand {
  let command: AtomicCommand
  let repeatTime: Int
}

func parse(code: String) -> [AtomicCommand] {
  return code.characters.map { AtomicCommand(rawValue: String($0))! }
}

func optimize(sequence: [AtomicCommand]) -> [MetaCommand] {
  var processingCommand: AtomicCommand!
  var processingCommandCount = 1
  var result = [MetaCommand]()
  for (index, command) in sequence.enumerated() {
    if processingCommand == nil {
      processingCommand = command
    } else if command == processingCommand && command != .endLoop && command != .startLoop {
      processingCommandCount += 1
    } else {
      let metaCommand = MetaCommand(command: processingCommand, repeatTime: processingCommandCount)
      result.append(metaCommand)
      processingCommand = command
      processingCommandCount = 1
    }

    if index == sequence.count - 1 {
      let metaCommand = MetaCommand(command: processingCommand, repeatTime: processingCommandCount)
      result.append(metaCommand)
    }
  }

  return result
}

var memoryCount = 1
var memoryPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: memoryCount)
var currentMemoryPosition = 0
var outputSequence: [UnicodeScalar] = []
var inputSequence: [UInt8]!
var loopPointers = [Int]()
var commandPointer = 0

func brainLuck(_ code: String, input: String) -> String {
  cleanUp()

  inputSequence = input.characters.map { UInt8(String($0).unicodeScalars.first!.value) }.reversed()
  let commandSequence = parse(code: code)
  let optimizedSequence = optimize(sequence: commandSequence)
  execute(sequence: optimizedSequence)
  return outputSequence.reduce("") { (result, current) -> String in
    return "\(result)\(current.escaped(asASCII: true))"
  }
}

func cleanUp() {
  currentMemoryPosition = 0
  memoryPointer.initialize(to: 0, count: memoryCount)
  memoryCount = 1
  memoryPointer.deallocate(capacity: memoryCount)
  memoryPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: memoryCount)
  outputSequence.removeAll()
  loopPointers.removeAll()
  commandPointer = 0
}

func execute(sequence: [MetaCommand]) {
  while (commandPointer < sequence.count) {
    let command = sequence[commandPointer]
    if execute(command: command) {
      commandPointer += 1
    }
  }
}

func execute(command: MetaCommand) -> Bool {
  switch command.command {
  case .moveForward:
    currentMemoryPosition += command.repeatTime
    if currentMemoryPosition >= memoryCount {
      memoryCount = currentMemoryPosition + 1
    }

  case .moveBackward:
    currentMemoryPosition -= command.repeatTime

  case .increaseValue:
    let value = memoryPointer[currentMemoryPosition]
    memoryPointer[currentMemoryPosition] = value &+ UInt8(command.repeatTime)

  case .decreaseValue:
    let value = memoryPointer[currentMemoryPosition]
    memoryPointer[currentMemoryPosition] = value &- UInt8(command.repeatTime)

  case .readValue:
    for _ in 0..<command.repeatTime {
      let inputScalar = inputSequence.popLast()!
      memoryPointer[currentMemoryPosition] = inputScalar
    }

  case .writeValue:
    for _ in 0..<command.repeatTime {
      outputSequence.append(UnicodeScalar(memoryPointer[currentMemoryPosition]))
    }

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


