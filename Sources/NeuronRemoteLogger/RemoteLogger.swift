

public enum Remote {
  case wandb
}

public protocol RemoteLogger {
  associatedtype LogPayload
  associatedtype InitPayload
  
  var type: Remote { get }
  
  init?(payload: InitPayload)
  func setup() throws
  func log(payload: LogPayload) throws
  func stop()
}
