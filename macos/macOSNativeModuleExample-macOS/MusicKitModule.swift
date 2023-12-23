//
//  MusicKitModule.swift
//  macOSNativeModuleExample-macOS
//
//  Created by Anthony on 12/22/23.
//

import Foundation
import MusicKit

@objc(MusicKitModule) class MusicKitModule: NSObject {
  @objc static func requiresMainQueueSetup() -> Bool { return true }
  
  /// Synchronous (main thread)
  @objc func currentAuthorizationStatus() -> String {
    if #available(macOS 12.0, *) {
      let status = MusicAuthorization.currentStatus.rawValue
      return status
    } else {
      return "Unsupported iOS"
    }
  }

  /// Asynchronous
  @objc func requestAuthorization(_ resolve: @escaping(RCTPromiseResolveBlock), rejecter reject: RCTPromiseRejectBlock) {
    if #available(macOS 12.0, *) {
      Task {
        let status = (await MusicAuthorization.request()).rawValue
        resolve(status)
      }
    } else {
      resolve("Unsupported iOS")
    }
  }
}
