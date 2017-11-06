//
//  Algorithm.swift
//  algorithmTester
//
//  Created by Rumata on 11/1/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import Foundation

enum AtomicCommand: String, CustomDebugStringConvertible {
  case moveForward = ">"
  case moveBackward = "<"
  case increaseValue = "+"
  case decreaseValue = "-"
  case readValue = ","
  case writeValue = "."
  case startLoop = "["
  case endLoop = "]"
  case nullify = "n"

  var debugDescription: String {
    return rawValue
  }
}

enum MetaCommand: CustomDebugStringConvertible {
  case fusing(command: AtomicCommand, repeatTime: Int)
  indirect case loop(sequence: [MetaCommand])

  var debugDescription: String {
    switch self {
    case .fusing(let command, let repeatTime):
      return "\(command.debugDescription)\(repeatTime)"
    case .loop(let sequence):
      return sequence.reduce("[", { (result, metaCommand) -> String in
        return "\(result) \(metaCommand.debugDescription)"
      }) + "]"
    }
  }
}

func parse(code: String) -> [AtomicCommand] {
  let regexp = try! NSRegularExpression(pattern: "\\[(-|\\+)\\]", options: [])
  let range = NSMakeRange(0, code.characters.count)
  let updatedCode = regexp.stringByReplacingMatches(in: code, options: [], range: range, withTemplate: "n")
  return updatedCode.characters.map { AtomicCommand(rawValue: String($0))! }
}

func fusing(sequence: [AtomicCommand]) -> [MetaCommand] {
  var processingCommand: AtomicCommand!
  var processingCommandCount = 1
  var result = [MetaCommand]()
  for (index, command) in sequence.enumerated() {
    if processingCommand == nil {
      processingCommand = command
    } else if command == processingCommand && command != .endLoop && command != .startLoop {
      processingCommandCount += 1
    } else {
      let metaCommand = MetaCommand.fusing(command: processingCommand, repeatTime: processingCommandCount)
      result.append(metaCommand)
      processingCommand = command
      processingCommandCount = 1
    }

    if index == sequence.count - 1 {
      let metaCommand = MetaCommand.fusing(command: processingCommand, repeatTime: processingCommandCount)
      result.append(metaCommand)
    }
  }

  return result
}

func wrappingLoops(in sequence: [MetaCommand]) -> [MetaCommand] {
  var loops: [Int: [MetaCommand]] = [:]
  var nestingLevel = 0
  loops[nestingLevel] = [MetaCommand]()
  for metaCommand in sequence {
    if case .fusing(let command, _) = metaCommand {
      if command == .startLoop {
        nestingLevel += 1
        loops[nestingLevel] = [MetaCommand]()
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

var memoryCount = 1
var memoryPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: memoryCount)
var currentMemoryPosition = 0
var outputSequence: [UnicodeScalar] = []
var inputSequence: [UInt8]!
var lastPointer: UnsafeMutablePointer<UInt8>!

func brainLuck(_ code: String, input: String) -> String {
  cleanUp()

  inputSequence = input.characters.map { UInt8(String($0).unicodeScalars.first!.value) }.reversed()
  let commandSequence = parse(code: code)
  let optimizedSequence = fusing(sequence: commandSequence)
  let loopRichSequence = wrappingLoops(in: optimizedSequence)
  execute(sequence: loopRichSequence)
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
  lastPointer = UnsafeMutablePointer<UInt8>(memoryPointer)
}

func execute(sequence: [MetaCommand]) {
  sequence.forEach { metaCommand in
    execute(metaCommand: metaCommand)
  }
}

func execute(metaCommand: MetaCommand) {
  switch metaCommand {
  case .fusing(let command, let repeatTime):
    switch command {
    case .moveForward:
      currentMemoryPosition += repeatTime
      if currentMemoryPosition >= memoryCount {
        memoryCount = currentMemoryPosition + 1
      }
      lastPointer = lastPointer.advanced(by: repeatTime)

    case .moveBackward:
      currentMemoryPosition -= repeatTime
      lastPointer = lastPointer.advanced(by: -repeatTime)

    case .increaseValue:
      let value = lastPointer.pointee
      lastPointer.pointee = value &+ UInt8(repeatTime)

    case .decreaseValue:
      let value = lastPointer.pointee
      lastPointer.pointee = value &- UInt8(repeatTime)

    case .readValue:
      for _ in 0..<repeatTime {
        let inputScalar = inputSequence.popLast()!
        lastPointer.pointee = inputScalar
      }

    case .writeValue:
      for _ in 0..<repeatTime {
        outputSequence.append(UnicodeScalar(lastPointer.pointee))
      }

    case .nullify:
      lastPointer.pointee = 0

    default:
      fatalError("incorrect command")
    }
  case .loop(let sequence):
    while lastPointer.pointee != 0 {
      execute(sequence: sequence)
    }
  }
}


