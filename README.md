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
    VisionApp.shared.configuration(token: "0d321e11be9a87782063251567587191", secret: "4dc3e71dce32ddc1d1edc91567587191", delegate: self)
    
    VisionApp.shared.startTracking(userToken: "<USER_TOKEN>")

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
