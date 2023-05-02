//
//  File.swift
//  
//
//  Created by William Vabrinskas on 5/1/23.
//

import Foundation
import PythonKit

public class Wandb: RemoteLogger {
  public var type: Remote = .wandb
  
  private var wandb: PythonObject?
  
  public init() throws {
    wandb = try Python.attemptImport("wandb")
    print(wandb?.login)
  }
  
}
