# VisionApp

## How to use

### Install
```ruby
pod 'VisionApp', :git => 'https://github.com/GrupoGO/VisionApp', :tag => '1.0'
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
