# VisionApp

### Important

> All ARKit configurations require an iOS device with an A9 or later processor. If your app otherwise supports other devices and offers augmented reality as a secondary feature, use this property to determine whether to offer AR-based features to the user. If your app requires ARKit for its core functionality, use the arkit key in the UIRequiredDeviceCapabilities section of your app's Info.plist to make your app available only on devices that support ARKit.

<img src="https://github.com/GrupoGO/VisionApp/blob/master/1.PNG?raw=true" width="30%" align="left">
<img src="https://github.com/GrupoGO/VisionApp/blob/master/2.PNG?raw=true" width="30%" align="left">
<img src="https://github.com/GrupoGO/VisionApp/blob/master/3.PNG?raw=true" width="30%">

## How to use

### Install
```ruby
pod 'VisionApp', :git => 'https://github.com/GrupoGO/VisionApp'
```

### Configure
```swift
import VisionApp

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // ...

    // MARK: - VisionApp configuration
    VisionApp.shared.configuration(token: "<YOUR_TOKEN>", secret: "<YOUR_SECRET>", delegate: self)

    // ...
}

extension AppDelegate: VisionAppDelegate {

    func userVAInfo(userToken: String) {
        // MARK: - TODO Save userToken for link with your user
    }
    
    func cancelVALogin() {
        // MARK: - TODO Check if the user wants to be shown again in VisionApp
    }

}
```

### Init VisionApp tracking
```swift
    // MARK: - Init VisionApp user session
    VisionApp.shared.startTracking(userToken: "<USER_TOKEN>")
    // OR Init with login request
    VisionApp.shared.startTracking()
```

### Stop VisionApp tracking
```swift
    // MARK: - Finish session and logout VisionApp user
    VisionApp.shared.stopTracking()
```
