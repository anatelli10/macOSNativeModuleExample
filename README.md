# macOSNativeModuleExample
> [!NOTE]
> This example is focused on writing logic/functions and **may not be applicable to creating user interfaces**.

Proof of concept/exemplification of how to write React Native Modules for macOS using Swift. Includes asynchronous and synchronous examples interacting with Apple MusicKit.

This almost entirely also applies to iOS, though for iOS you should probably instead use the [Expo Modules API](https://docs.expo.dev/modules/overview/).

## Implementation Files
- [App.tsx](https://github.com/anatelli10/macOSNativeModuleExample/blob/main/App.tsx)
- [macos/macOSNativeModuleExample-macOS/MusicKitModule.swift](https://github.com/anatelli10/macOSNativeModuleExample/blob/main/macos/macOSNativeModuleExample-macOS/MusicKitModule.swift)
- [macos/macOSNativeModuleExample-macOS/MusicKitModule.m](https://github.com/anatelli10/macOSNativeModuleExample/blob/main/macos/macOSNativeModuleExample-macOS/MusicKitModule.m)

## Demo
https://github.com/anatelli10/macOSNativeModuleExample/assets/70483566/f31b6bf2-cf3c-4cd9-afd6-59bf9b318bca

# How to create a React Native Module for macOS

<details>
  <summary>Instructions</summary>

1. [Install React Native for macOS](https://microsoft.github.io/react-native-windows/docs/rnm-getting-started#install-react-native-for-macos)

   ```shell
   Do you want to install CocoaPods now? y
   ```

   You'll want to make sure your project can build/run using Xcode.

    <details>
      <summary>⚠️ Build error: "Command PhaseScriptExecution failed with a nonzero exit code"</summary>
  
    There may be other better solutions for this such as changing Node related configuration or updating CocoaPods, but this worked for me:
    
    Modify `node_modules/react-native/scripts/find-node.sh` @ L7
    
    ```diff
    - set -e
    + set +e
    ```
    see https://github.com/facebook/react-native/issues/36762#issuecomment-1535910492
    </details>

1. From project root dir run `xed -b macos` to open Xcode.
1. Navigate to the folder containing `AppDelegate`.

   <img width="266" alt="image" src="https://github.com/anatelli10/macOSNativeModuleExample/assets/70483566/a9a1cd3a-7f08-44c6-8dd0-7b57be111875">

1. Create a new macOS Swift file.

   <img width="727" alt="image" src="https://github.com/anatelli10/macOSNativeModuleExample/assets/70483566/566dbd2d-cf8d-478a-882e-2c9646d642dc">

   The name you use for this file will be reused throughout the project including in your React code. Leave the options to default and create. I'm naming mine `MusicKitModule` as I'll be exporting some methods that utilize Apple MusicKit. Suffixed with `Module` to prevent confusion, but use whatever naming you like.

1. Create the bridging header automatically.

   <img width="197" alt="image" src="https://github.com/anatelli10/macOSNativeModuleExample/assets/70483566/d0a3acb5-2d56-4944-91e6-208089bdf2e6">

   The name of this file is automatically prefixed by your Xcode project name.

1. Add `#import <React/RCTBridgeModule.h>` to the `...-Bridging-Header.h` file.
1. Add the following boilerplate to your Swift file
   ```swift
   @objc(YourFileName) class YourFileName: NSObject {
     @objc static func requiresMainQueueSetup() -> Bool { return true }
   }
   ```
1. Create a new Objective-C file with the same name

   <img width="725" alt="image" src="https://github.com/anatelli10/macOSNativeModuleExample/assets/70483566/22914ddc-aeda-48d0-bbda-c54931e38009">

1. Add `#import <React/RCTBridgeModule.h>` to the `YourFileName.m` file.
1. In `macos/YourProjectName-macOS/Info.plist`, add the following key/string pair
   > ```diff
   >    <key>NSSupportsSuddenTermination</key>
   >    <true/>
   > +  <key>NSAppleMusicUsageDescription</key>
   > +  <string>A message that tells the user why the app is requesting access to the user's media library.</string>
   >    </dict>
   > </plist>
   > ```
1. Test by running the Xcode project.
1. Congratulations! You've completed all boilerplate. See below for examples on creating methods.

</details>

# Example asynchronous method

<details>
  <summary>Example</summary>

> ℹ️ There also exists the ability to create callback based methods using `RCTResponseSenderBlock, RCTResponseErrorBlock`, but I will not be using those here.

## Swift

- Expose the function using `@objc`
- Last two function parameters must be
  `RCTPromiseResolveBlock, RCTPromiseRejectBlock`
- Use `@escaping` to use `resolve` or `reject` in a `Task`

```swift
@objc(MusicKitModule) class MusicKitModule: NSObject {
  @objc static func requiresMainQueueSetup() -> Bool { return true }

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
```

## Objective-C (`.m`)

- Register the module once using `RCT_EXTERN_MODULE`
- Register a method using `RCT_EXTERN_METHOD`, providing the method signature.

```objective-c
@interface RCT_EXTERN_MODULE(MusicKitModule, NSObject)

RCT_EXTERN_METHOD(requestAuthorization: (RCTPromiseResolveBlock)resolve
                  rejecter: (RCTPromiseRejectBlock)reject)

@end
```

## React

This is a minimal example, you could expand this by following [this guide](https://reactnative.dev/docs/native-modules-ios?package-manager=npm#better-native-module-export).

- Import `NativeModules`
- Your module is a property on the `NativeModules` import, corresponds to the same file name used in ObjC/Swift.
- Use `await` (or chain `.then()`)

```tsx
import {NativeModules} from 'react-native';
// Optionally destructure
const {MusicKitModule} = NativeModules;

const status = await MusicKitModule.requestAuthorization();
```

</details>

# Example synchronous method

<details>
  <summary>Example</summary>

> ⚠️ Runs a blocking function on the main thread. Highly discouraged by React Native. Use at own risk and please know what you're doing.

## Swift

- Expose the function using `@objc`

```swift
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
}
```

## Objective-C (`.m`)

- Register the module once using `RCT_EXTERN_MODULE`
- Register a method using `RCT_EXTERN__BLOCKING_SYNCHRONOUS_METHOD`, providing the method signature.

```objective-c
@interface RCT_EXTERN_MODULE(MusicKitModule, NSObject)

RCT_EXTERN__BLOCKING_SYNCHRONOUS_METHOD(currentAuthorizationStatus)

@end
```

## React

This is a minimal example, you could expand this by following [this guide](https://reactnative.dev/docs/native-modules-ios?package-manager=npm#better-native-module-export).

- Import `NativeModules`
- Your module is a property on the `NativeModules` import, corresponds to the same file name used in ObjC/Swift.

```tsx
import {NativeModules} from 'react-native';
// Optionally destructure
const {MusicKitModule} = NativeModules;

const status = MusicKitModule.currentAuthorizationStatus();
```

</details>

# Resources

- [iOS Native Modules · React Native](https://reactnative.dev/docs/native-modules-ios)
- [iOS Native Module on React Native by Pasindu Yeshan Abeysinghe](https://medium.com/@pasinduyeshann/ios-native-module-on-react-native-fa9429703ca9)
