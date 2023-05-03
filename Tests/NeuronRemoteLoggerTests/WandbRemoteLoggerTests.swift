import XCTest
@testable import NeuronRemoteLogger

extension XCTestCase {
  var isGithubCI: Bool {
    if let value = ProcessInfo.processInfo.environment["CI"] {
      return value == "true"
    }
    return false
  }
}

final class WandbRemoteLoggerTests: XCTestCase {
  
  func test_wandbInit() {
    // the github CLI definitely doesn't have wandb installed
    guard isGithubCI == false else { return }
    
    let epochs = 10
    let lr = 0.01
    
    let payload = Wandb.InitializePayload(projectName: "NeuronTest",
                                          config: ["learning_rate": lr.pythonObject,
                                                   "epochs": epochs.pythonObject])
    guard let wandb = Wandb(payload: payload) else {
      XCTFail()
      return
    }
      
    do {
      try wandb.setup()
    } catch {
      XCTFail(error.localizedDescription)
    }
    
    let offset = Double.random(in: 0...1) / 5
    
    for epoch in 0..<epochs {
      let e = Double(epoch)
      let acc = 1 - pow(2, -e - Double.random(in: 0...1) / e - offset)
      let loss = pow(2, -e + Double.random(in: 0...1) / e + offset)
      let payload = ["accuracy": acc.pythonObject, "loss": loss.pythonObject]
      do {
        try wandb.log(payload: payload)
      } catch {
        XCTFail(error.localizedDescription)
      }
    }
    
  }
}
