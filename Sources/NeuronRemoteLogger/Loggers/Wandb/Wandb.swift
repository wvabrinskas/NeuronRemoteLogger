//
//  File.swift
//  
//
//  Created by William Vabrinskas on 5/1/23.
//

import Foundation
import Logger
import PythonKit
import NumSwift

public class Wandb: RemoteLogger, Logger {
  public enum AlertLevel: String, Encodable, PythonConvertible {
    public var pythonObject: PythonKit.PythonObject {
      name.pythonObject
    }
    
    case info, warn, error
    
    var name: String {
      rawValue.uppercased()
    }
  }
  
  public struct Alert: Encodable, PythonConvertible {
    public var pythonObject: PythonKit.PythonObject {
      var object = ["title": title.pythonObject,
                    "text": text.pythonObject]
      
      if let level {
        object["level"] = level.pythonObject
      }
      
      if let waitDurationSeconds {
        object["wait_duration"] = waitDurationSeconds.pythonObject
      }
      
      return object.pythonObject
    }
    
    let title: String
    let text: String
    let level: AlertLevel?
    let waitDurationSeconds: Int?
    
    public init(title: String,
                text: String,
                level: AlertLevel? = nil,
                waitDurationSeconds: Int? = nil) {
      self.title = title
      self.text = text
      self.level = level
      self.waitDurationSeconds = waitDurationSeconds
    }
  }
  
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
  
  public struct EnvironmentPayload {
    public let sitePackages: String
    
    public init(sitePackages: String) {
      self.sitePackages = sitePackages
    }
  }
  
  public struct InitializePayload: PythonConvertible {
    public var pythonObject: PythonKit.PythonObject {
      config.mapValues { $0.pythonObject }.pythonObject
    }
    
    var projectName: String?
    var jobType: String?
    var config: [String: PythonConvertible]
    var entity: String?
    var reinit: Bool?
    var tags: [String]?
    var group: String?
    var name: String?
    var notes: String?
    var configExcludeKeys: [String]?
    var configIncludeKeys: [String]?
    var anonymous: String?
    var mode: String?
    var allowValChange: Bool?
    var resume: String?
    var force: Bool?
    var tensorboard: Bool?
    var syncTensorboard: Bool?
    var monitorGym: Bool?
    var saveCode: Bool?
    var id: String?
    
    public init(projectName: String? = nil,
                jobType: String? = nil,
                config: [String : PythonConvertible],
                entity: String? = nil,
                reinit: Bool? = nil,
                tags: [String]? = nil,
                group: String? = nil,
                name: String? = nil,
                notes: String? = nil,
                configExcludeKeys: [String]? = nil,
                configIncludeKeys: [String]? = nil,
                anonymous: String? = nil,
                mode: String? = nil,
                allowValChange: Bool? = nil,
                resume: String? = nil,
                force: Bool? = nil,
                tensorboard: Bool? = nil,
                syncTensorboard: Bool? = nil,
                monitorGym: Bool? = nil,
                saveCode: Bool? = nil,
                id: String? = nil) {
      self.projectName = projectName
      self.jobType = jobType
      self.config = config
      self.entity = entity
      self.reinit = reinit
      self.tags = tags
      self.group = group
      self.name = name
      self.notes = notes
      self.configExcludeKeys = configExcludeKeys
      self.configIncludeKeys = configIncludeKeys
      self.anonymous = anonymous
      self.mode = mode
      self.allowValChange = allowValChange
      self.resume = resume
      self.force = force
      self.tensorboard = tensorboard
      self.syncTensorboard = syncTensorboard
      self.monitorGym = monitorGym
      self.saveCode = saveCode
      self.id = id
    }
  }
  
  public var logLevel: LogLevel = .high
  public var type: Remote = .wandb
  
  private var wandb: PythonObject?
  private var np: PythonObject?
  private let initalizePayload: InitializePayload
  private var initObject: PythonObject?
  
  required public init?(payload: InitializePayload,
                        env: EnvironmentPayload? = nil) {
    self.initalizePayload = payload
  
    if let env {
      let os = Python.import("os")
      let sys = Python.import("sys")
      sys.path.append(os.path.abspath(env.sitePackages))
    }
    
    do {
      wandb = try Python.attemptImport("wandb")
    } catch {
      self.log(type: .error, message: "Please run `pip install wandb` on the host computer. - \(error.localizedDescription)")
      return nil
    }
    
    
    do {
      np = try Python.attemptImport("numpy")
    } catch {
      self.log(type: .error, message: "Please run `pip install numpy` on the host computer. - \(error.localizedDescription)")
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
                              job_type: initalizePayload.jobType,
                              entity: initalizePayload.entity,
                              reinit: initalizePayload.reinit,
                              tags: initalizePayload.tags,
                              group: initalizePayload.group,
                              name: initalizePayload.name,
                              notes: initalizePayload.notes,
                              config_exclude_keys: initalizePayload.configExcludeKeys,
                              config_include_keys: initalizePayload.configIncludeKeys,
                              anonymous: initalizePayload.anonymous,
                              mode: initalizePayload.mode,
                              allow_val_change: initalizePayload.allowValChange,
                              resume: initalizePayload.resume,
                              force: initalizePayload.force,
                              tensorboard: initalizePayload.tensorboard,
                              sync_tensorboard: initalizePayload.syncTensorboard,
                              monitor_gym: initalizePayload.monitorGym,
                              save_code: initalizePayload.saveCode,
                              id: initalizePayload.id)
  }
  
  public func alert(_ alert: Alert) {
    guard let wandb else { return }
    wandb.alert(alert.pythonObject)
  }
  
  public func log(payload: [String : PythonObject]) throws {
    guard let wandb else { return }

    wandb.log(payload.pythonObject)
    
    log(type: .message,
        priority: .medium,
        message: "Logging event for wandb. Payload: \(payload)")
  }
  
  public func buildImage(data: [[[Float]]], name: String) -> PythonObject? {
    guard let wandb, let np else { return nil }
    
    let npArray = np.array(data)
    
    let pythonTuple = PythonObject(tupleOf: 1, 2, 0)
    let reshaped = np.transpose(npArray, pythonTuple)
    let image = wandb.Image(reshaped, caption: name)
    
    return image
  }
  
  public func buildTable(columns: String..., values: PythonObject...) -> PythonObject? {
    guard let wandb, columns.isEmpty == false else { return nil }
    
    let table = wandb.Table(data: values,
                            columns: columns)
    return table
  }
  
  public func runCommand(_ block: (_ wandb: PythonObject) -> PythonObject?) -> PythonObject? {
    guard let wandb else { return nil }
    
    return block(wandb)
  }
  
  public func stop() {
    guard let wandb else { return }
    
    wandb.finish()
  }
  
  // MARK: Private

}
