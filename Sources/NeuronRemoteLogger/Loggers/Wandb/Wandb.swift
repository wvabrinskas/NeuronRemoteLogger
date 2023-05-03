//
//  File.swift
//  
//
//  Created by William Vabrinskas on 5/1/23.
//

import Foundation
import Logger
import PythonKit

@available(macOS 12.3, *)
public class Wandb: RemoteLogger, Logger {
  public typealias LogPayload = [String: PythonObject]
  public typealias InitPayload = InitializePayload

  public enum WandbError: Error, LocalizedError {
    case pythonError(message: String)
    case payloadDecodeError
    case initError
    
    public var errorDescription: String? {
      switch self {
      case .pythonError(let message):
        return message
      case .payloadDecodeError:
        return "Could not parse initialize payload."
      case .initError:
        return "Could not initialize wandb with given payload."
      }
    }
  }
  
  public struct InitializePayload: PythonConvertible {
    public var pythonObject: PythonKit.PythonObject {
      return config.pythonObject
    }
    
    var projectName: String
    var jobType: String = "train"
    var config: [String: PythonObject]
  }
  
  public var logLevel: LogLevel = .high
  public var type: Remote = .wandb
  
  private var wandb: PythonObject?
  private let initalizePayload: InitializePayload
  private var initObject: PythonObject?
  
  required public init?(payload: InitializePayload) {
    self.initalizePayload = payload
    
    do {
      wandb = try Python.attemptImport("wandb")
    } catch {
      self.log(type: .error, message: "Please run `pip install wandb` on the host computer. - \(error.localizedDescription)")
      return nil
    }
  }
  
  public func setup() throws {
    guard let wandb else { return }
    
    // maybe use python to inject the api key?
    let result = wandb.login()
    
    guard result == true else {
      self.log(type: .error, message: "Please call `wandb login` from the commandline to log in first")
      throw WandbError.pythonError(message: "Please call `wandb login` from the commandline to log in first")
    }
    
    let object = initalizePayload.pythonObject
    initObject = wandb.`init`(config: object,
                              project: initalizePayload.projectName,
                              job_type: initalizePayload.jobType)
  }
  
  public func log(payload: [String : PythonObject]) throws {
    guard let wandb else { return }

    wandb.log(payload.pythonObject)
    
    log(type: .message,
        priority: .medium,
        message: "Logging event for wandb. Payload: \(payload)")
  }
  
  // MARK: Private

}

@available(macOS 12.3, *)
extension Encodable {
  func asDictionary<K: Hashable, V>() -> Dictionary<K,V>? {
    do {
      let data = try JSONEncoder().encode(self)
      let jsonData = try JSONSerialization.jsonObject(with: data)
      return jsonData as? Dictionary<K,V>
    } catch {
      print(error.localizedDescription)
      return nil
    }
  }
}
