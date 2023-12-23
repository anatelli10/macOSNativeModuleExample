//
//  MusicKitModule.m
//  macOSNativeModuleExample-macOS
//
//  Created by Anthony on 12/22/23.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(MusicKitModule, NSObject)

RCT_EXTERN_METHOD(requestAuthorization: (RCTPromiseResolveBlock)resolve
                  rejecter: (RCTPromiseRejectBlock)reject)

RCT_EXTERN__BLOCKING_SYNCHRONOUS_METHOD(currentAuthorizationStatus)

@end
