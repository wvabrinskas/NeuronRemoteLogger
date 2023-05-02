import XCTest
@testable import NeuronRemoteLogger

final class NeuronRemoteLoggerTests: XCTestCase {
  
  func test_wandbLogin() {
    do {
      let wandb = try Wandb()
    } catch {
      XCTFail(error.localizedDescription)
    }
  }
}
