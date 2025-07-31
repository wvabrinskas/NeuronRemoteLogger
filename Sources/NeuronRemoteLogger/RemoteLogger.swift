
import Foundation

public enum Remote {
  case wandb
}

public protocol RemoteLogger {
  associatedtype LogPayload
  associatedtype InitPayload
  associatedtype EnvPayload
  
  var type: Remote { get }
  
  init?(payload: InitPayload, env: EnvPayload?)
  func setup() throws
  func log(payload: LogPayload) throws
  func stop()
}

extension RemoteLogger {
  func shell(_ command: String) throws -> String {
      let task = Process()
      let pipe = Pipe()
      
      task.standardOutput = pipe
      task.standardError = pipe
      task.arguments = ["-c", command]
      task.launchPath = "/bin/zsh"
      task.standardInput = nil
      task.launch()
      
      let data = pipe.fileHandleForReading.readDataToEndOfFile()
    guard let output = String(data: data, encoding: .utf8) else {
      throw NSError(domain: "Could not read output from shell command", code: 0, userInfo: nil)
    }
      
      return output
  }
}
