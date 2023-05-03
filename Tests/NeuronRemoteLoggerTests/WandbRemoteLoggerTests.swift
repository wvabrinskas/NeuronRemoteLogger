import XCTest
@testable import NeuronRemoteLogger

@available(macOS 12.3, *)
final class WandbRemoteLoggerTests: XCTestCase {
  
  func test_wandbLogin() {
    
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
      let acc = pow(1 - 2, -e -  Double.random(in: 0...1) / e - offset)
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
