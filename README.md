# Soundboard

[![iOS starter workflow](https://github.com/natanleung/soundboard-ios/actions/workflows/ios.yml/badge.svg)](https://github.com/natanleung/soundboard-ios/actions/workflows/ios.yml)
[![Xcode - Build and Analyze](https://github.com/natanleung/soundboard-ios/actions/workflows/objective-c-xcode.yml/badge.svg)](https://github.com/natanleung/soundboard-ios/actions/workflows/objective-c-xcode.yml)

Soundboard is an iOS app that records and plays sound bites.
Users can create, save, and delete their custom audio recordings directly within the application.

Download the official build from the [App Store](https://apps.apple.com/us/app/soundboard-record-playback/id6466728387).

## Getting Started

### Requirements

* Compatible macOS device
* Install Xcode and Simulator from the [App Store](https://apps.apple.com/us/app/xcode/id497799835?mt=12) or [Apple Developer](https://developer.apple.com/xcode/).
* Optional: Install Xcode CLI
  
  ```shell
  xcode-select --install
  ```

Note: Soundboard was developed using a MacBook Air (M2) and Xcode 14.3.1. Testing was performed using an iPhone SE (3rd generation) and iOS 16.4.

### Running on physical iOS device

Enable Developer Mode on physical device under `Settings > Privacy & Security > Developer Mode`.

It seems running an Xcode app on a physical device is limited to [Running via Xcode GUI](#running-via-xcode-gui).

### Running via Xcode GUI

Open the project file (link here) using Xcode. Under the `Product` tab, you can build (`⌘B`) or run (`⌘R`).
Alternatively, simply select the play button (`▶︎`) in the top left of the Xcode window.

Next, select a Run Destination, either a physical device or iOS simulator, on the top of the Xcode window.

This should compile the project and launch the application on the selected device.

### Running on iOS Simulator via Xcode CLI

1. Select a device type
```shell
xcrun simctl list devicetypes
```

2. Select a runtime
```shell
xcrun simctl list runtimes
```

3. Create simulator
```shell
xcrun simctl create $SIM_NAME $DEVICE_TYPE $RUNTIME
```

3. Boot simulator
```shell
xcrun simctl boot $DEVICE_ID
```

4. Build Xcode project
```shell
xcodebuild -scheme Soundboard -project Soundboard.xcodeproj -destination "name=$SIM_NAME" -derivedDataPath $PATH
```

5. Open Simulator application
```shell
open -a Simulator
```

6. Install app on Simulator
```shell
xcrun simctl install booted ${PATH}/Build/Products/Debug-iphonesimulator/Soundboard.app
```

7. Get bundle identifier
```shell
mdls -name kMDItemCFBundleIdentifier -r ${PATH}/Build/Products/Debug-iphonesimulator/Soundboard.app
```

8. Launch app on Simulator
```shell
xcrun simctl launch booted $BUNDLE_ID
```

## Learn More

* [Programming with Objective-C](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC)
* [Cocoa Fundamentals Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CocoaFundamentals)
* [Understanding Auto Layout](https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/AutolayoutPG)
* [UIKit](https://developer.apple.com/documentation/uikit)
* [AVKit](https://developer.apple.com/documentation/avkit)

## License

See [LICENSE](LICENSE).
