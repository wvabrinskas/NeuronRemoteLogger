

public enum Remote {
  case wandb
}

public protocol RemoteLogger {
  var type: Remote { get }
}
