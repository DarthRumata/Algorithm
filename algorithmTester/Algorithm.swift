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
  case nullify = "n"
}

enum ComplexCommand {
  case fusing(command: AtomicCommand, repeatTime: Int)
  indirect case loop(sequence: [ComplexCommand])
}

var memoryCount = 30000
var memoryPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: memoryCount)
var currentMemoryPosition = 0
var outputSequence: [UnicodeScalar] = []
var inputSequence: [UInt8]!

func parse(code: String) -> [AtomicCommand] {
  let regexp = try! NSRegularExpression(pattern: "\\[(-|\\+)\\]", options: [])
  let range = NSMakeRange(0, code.characters.count)
  let updatedCode = regexp.stringByReplacingMatches(in: code, options: [], range: range, withTemplate: "n")
  return updatedCode.characters.map { AtomicCommand(rawValue: String($0))! }
}

func fusing(sequence: [AtomicCommand]) -> [ComplexCommand] {
  var processingCommand: AtomicCommand!
  var processingCommandCount = 1
  var result = [ComplexCommand]()
  for (index, command) in sequence.enumerated() {
    if processingCommand == nil {
      processingCommand = command
    } else if command == processingCommand && command != .endLoop && command != .startLoop {
      processingCommandCount += 1
    } else {
      let metaCommand = ComplexCommand.fusing(command: processingCommand, repeatTime: processingCommandCount)
      result.append(metaCommand)
      processingCommand = command
      processingCommandCount = 1
    }

    if index == sequence.count - 1 {
      let metaCommand = ComplexCommand.fusing(command: processingCommand, repeatTime: processingCommandCount)
      result.append(metaCommand)
    }
  }

  return result
}

func wrappingLoops(in sequence: [ComplexCommand]) -> [ComplexCommand] {
  var loops: [Int: [ComplexCommand]] = [:]
  var nestingLevel = 0
  loops[nestingLevel] = [ComplexCommand]()
  for metaCommand in sequence {
    if case .fusing(let command, _) = metaCommand {
      if command == .startLoop {
        nestingLevel += 1
        loops[nestingLevel] = [ComplexCommand]()
      } else if command == .endLoop {
        let currentLoop = loops[nestingLevel]!
        nestingLevel -= 1
        var outerLoop = loops[nestingLevel]!
        outerLoop.append(.loop(sequence: currentLoop))
        loops[nestingLevel] = outerLoop
      } else {
        var currentLoop = loops[nestingLevel]!
        currentLoop.append(metaCommand)
        loops[nestingLevel] = currentLoop
      }
    }
  }

  return loops[0]!
}

func brainLuck(_ code: String, input: String) -> String {
  cleanUp()

  inputSequence = input.characters.map { UInt8(String($0).unicodeScalars.first!.value) }.reversed()
  let commandSequence = parse(code: code)
  let optimizedSequence = fusing(sequence: commandSequence)
  let loopRichSequence = wrappingLoops(in: optimizedSequence)

  execute(sequence: loopRichSequence)
  let result = outputSequence.reduce("") { (result, current) -> String in
    return "\(result)\(current)"
  }

  return result
}

func execute(sequence: [ComplexCommand]) {
  sequence.forEach { metaCommand in
    execute(metaCommand: metaCommand)
  }
}

func execute(metaCommand: ComplexCommand) {
  switch metaCommand {
  case .fusing(let command, let repeatTime):
    switch command {
    case .moveForward:
      currentMemoryPosition += repeatTime

    case .moveBackward:
      currentMemoryPosition -= repeatTime

    case .increaseValue:
      let value = memoryPointer[currentMemoryPosition]
      memoryPointer[currentMemoryPosition] = value &+ UInt8(repeatTime)

    case .decreaseValue:
      let value = memoryPointer[currentMemoryPosition]
      memoryPointer[currentMemoryPosition] = value &- UInt8(repeatTime)

    case .readValue:
      for _ in 0..<repeatTime {
        let inputScalar = inputSequence.popLast()!
        memoryPointer[currentMemoryPosition] = inputScalar
      }

    case .writeValue:
      for _ in 0..<repeatTime {
        outputSequence.append(UnicodeScalar(memoryPointer[currentMemoryPosition]))
      }

    case .nullify:
      memoryPointer[currentMemoryPosition] = 0

    default:
      fatalError("incorrect command")
    }
  case .loop(let sequence):
    while memoryPointer[currentMemoryPosition] != 0 {
      execute(sequence: sequence)
    }
  }
}

func cleanUp() {
  currentMemoryPosition = 0
  memoryPointer.deallocate(capacity: memoryCount)
  memoryPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: memoryCount)
  memoryPointer.initialize(to: 0, count: memoryCount)
  outputSequence.removeAll()
}
