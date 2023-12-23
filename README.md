# macOSNativeModuleExample

Proof of concept/exemplification of how to write React Native Modules for macOS using Swift. Includes asynchronous and synchronous examples. This almost entirely also applies to iOS, though for iOS you should probably instead use the [Expo Modules API](https://docs.expo.dev/modules/overview/).

https://github.com/anatelli10/macos-native-module-example/assets/70483566/f34b6bde-63d0-4bf5-87a4-f8a4e2c12318

# How to create a React Native Module for macOS

<details>
  <summary>Instructions</summary>

1. [Install React Native for macOS](https://microsoft.github.io/react-native-windows/docs/rnm-getting-started#install-react-native-for-macos)

   ```shell
   Do you want to install CocoaPods now? y
   ```

   You'll want to make sure your project can build/run using Xcode.

   > ⚠️ If you run into the following build error:
   >
   > ```
   > Command PhaseScriptExecution failed with a nonzero exit code
   > ```
   >
   > Modify `node_modules/react-native/scripts/find-node.sh` @ L7
   >
   > ```diff
   > - set -e
   > + set +e
   > ```
   >
   > see https://github.com/facebook/react-native/issues/36762#issuecomment-1535910492
   >
   > There may be other better solutions for this such as updating CocoaPods, but this worked for me and took way too long to find the solution for so I'm not going to spend any more time on it. 🤣

1. From project root dir run `xed -b macos` to open Xcode.
1. Navigate to the folder containing `AppDelegate`.

   <img width="546" alt="image" src="https://github.com/anatelli10/macos-native-module-example/assets/70483566/2ff0622f-051d-4a10-9a6d-1ed33292ff57">

1. Create a new macOS Swift file.

   <img width="729" alt="image" src="https://github.com/anatelli10/macos-native-module-example/assets/70483566/8aabe37d-f49f-40b7-9920-4168f2ffac7e">

   The name you use for this file will be reused throughout the project including in your React code. Leave the options to default and create. I'm naming mine `MusicKitModule` as I'll be exporting some methods that utilize Apple MusicKit. Suffixed with `Module` to prevent confusion, but use whatever naming you like.

1. Create the bridging header automatically.

   <img width="456" alt="image" src="https://github.com/anatelli10/macos-native-module-example/assets/70483566/819cd0c8-6d8a-4edf-a290-8563e412db72">

   The name of this file is automatically prefixed by your Xcode project name.

1. Add `#import <React/RCTBridgeModule.h>` to the `...-Bridging-Header.h` file.
1. Add the following boilerplate to your Swift file
   ```swift
   @objc(YourFileName) class YourFileName: NSObject {
     @objc static func requiresMainQueueSetup() -> Bool { return true }
   }
   ```
1. Create a new Objective-C file with the same name

   <img width="727" alt="image" src="https://github.com/anatelli10/macos-native-module-example/assets/70483566/fb53eda0-de35-4434-aa08-ea04bbdccb24">

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

# Example Asynchronous method

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
- Use `await

```tsx
import {NativeModules} from 'react-native';
// Optionally destructure
const {MusicKitModule} = NativeModules;

const status = await MusicKitModule.requestAuthorization();
```

</details>

# Example Synchronous method

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
