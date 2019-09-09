# VisionApp

### ⚠️ Important

> VisionApp is based on ARKit configurations and face tracking. Is available only on iOS devices with a front-facing TrueDepth camera with iOS 12.0 or later.

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

    func userVAInfo(userToken: String, userName:String, userProfile:String?) {
        // MARK: - TODO Save userToken from userName to link with your user
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

### Change user profile
```swift
    // MARK: - Returns the number of user profiles
    let totalProfiles = VisionApp.shared.profilesNumber

    // MARK: - Launch profile selection
    VisionApp.shared.profileSelection() // only if user profiles number > 1
```
