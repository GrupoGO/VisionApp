# VisionApp

### ⚠️ Important

> VisionApp is based on ARKit configurations and face tracking. Is available only on iOS devices with a front-facing TrueDepth camera with iOS 12.0 or later.

<img src="https://github.com/GrupoGO/VisionApp/blob/master/1.PNG?raw=true" width="30%" align="left">
<img src="https://github.com/GrupoGO/VisionApp/blob/master/2.jpg?raw=true" width="30%" align="left">
<img src="https://github.com/GrupoGO/VisionApp/blob/master/3.PNG?raw=true" width="30%">

## How to use

### Install
```ruby
pod 'VisionApp', :git => 'https://github.com/GrupoGO/VisionApp'
```

### Configure

It's mandatory to add a `NSCameraUsageDescription` in the `Info.plist`.

```swift
import VisionApp

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // ...

    // MARK: - VisionApp configuration
    VisionApp.shared.configuration(token: <YOUR_TOKEN>, secret: <YOUR_SECRET>, delegate: self)

    // ...
}

extension AppDelegate: VisionAppDelegate {

    func userVAInfo(userToken: String, userName:String, profileId:Int?, profileName:String?)
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
    VisionApp.shared.startTracking(userToken: <USER_TOKEN>, userProfile: <PROFILE_ID>)
    // OR init tracking or login request
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

## Apple's review considerations

### FAQs

**Provide information on how to locate features in your app that use TrueDepth APIs**

Please just enable the “Eye Protection” function from the home screen of the app.

**What information is your app collecting using the TrueDepth API?**

1. Distance from the user’s head to the device,
2. Ambient light level,
3. Time.

**For what purposes are you collecting this information? Please provide a complete and clear explanation of all planned uses of this data.**

VisionApp uses the TrueDepth API in order to measure the distance from the user’s head to the device and ambient light levels. This information can be used by the user in order to better control their device-use habits, and also can be shared with a vision professional (such as an eye doctor) to determine if said habits are healthy, for example within the context of World Health Organization's recommendation regarding screen time.

**Will the data be shared with any third parties? Where will this information be stored?**

In the event that the user links his VisionApp account, with that of our app, the device usage data will be stored on the VisionApp servers, for the exploitation of the same by the user. The app delivers the data to the VisionApp API so that the user can dispose of them, and make use of them in the terms that VisionApp informs at the time of create the account at http://visionapp.org

### Privacy Policy

Your app Privacy Policy needs to include all of the required information explaining: collection, use, disclosure, sharing and retention of user’s face data.
