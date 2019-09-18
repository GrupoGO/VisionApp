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

### Apple review FAQs

**What information is your app collecting using the TrueDepth API?**
_Information is being collected on the habit of using the mobile device, in terms of distance from the screen to the user's face, and ambient lighting._

**For what purposes are you collecting this information? Please provide a complete and clear explanation of all planned uses of this data.**
_The user who grants our app permissions to collect this data, does so by linking his VisionApp account with the application account, to:_
\n_a) That you are shown alerts in our app when the distance you are using the terminal is too short (less than 30 cm)_
_b) Collect the usage data of out app in the user's VisionApp account_

**Will the data be shared with any third parties? Where will this information be stored?**
_In the event that the user links his VisionApp account, with that of our app, the device usage data will be stored on the VisionApp servers, for the exploitation of the same by the user. Our app at no time, makes use of this data, if not that it delivers them to the VisionApp API so that the user can dispose of them, and make use of them in the terms that VisionApp informs at the time of create your account at http://visionapp.org_
