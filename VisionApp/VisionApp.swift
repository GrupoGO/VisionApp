//
//  VisionApp.swift
//  VisionApp
//
//  Created by Emilio Cubo Ruiz on 04/09/2019.
//  Copyright © 2019 VisionApp. All rights reserved.
//

import UIKit
import ARKit
import SceneKit

public protocol VisionAppDelegate {
    func userVAInfo(userToken: String, userName:String, profileId:Int?, profileName:String?)
    func cancelVALogin()
}

public class VisionApp: NSObject {

    public static let shared = VisionApp()
    var delegate:VisionAppDelegate?

    var sceneView: ARSCNView?
    var contentControllers: [VirtualContentType: VirtualContentController] = [:]
    var currentFaceAnchor: ARFaceAnchor?
    var faceNode = SCNNode()
    var leftEye = SCNNode()
    var rightEye = SCNNode()

    var lastSecond:Date?
    var deviceId:Int?
    var currentUser:VAUser? = nil
    var currentProfile:VAProfile? = nil
    var hiddenView:HiddenView?
    

    var selectedVirtualContent: VirtualContentType! {
        didSet {
            guard oldValue != nil, oldValue != selectedVirtualContent, sceneView != nil else { return }
            
            // Remove existing content when switching types.
            contentControllers[oldValue]?.contentNode?.removeFromParentNode()
            
            // If there's an anchor already (switching content), get the content controller to place initial content.
            // Otherwise, the content controller will place it in `renderer(_:didAdd:for:)`.
            if let anchor = currentFaceAnchor, let node = sceneView!.node(for: anchor),
                let newContent = selectedContentController.renderer(sceneView!, nodeFor: anchor) {
                node.addChildNode(newContent)
            }
        }
    }
    
    var selectedContentController: VirtualContentController {
        if let controller = contentControllers[selectedVirtualContent] {
            return controller
        } else {
            let controller = selectedVirtualContent.makeController()
            contentControllers[selectedVirtualContent] = controller
            return controller
        }
    }

    public func configuration(token:String, secret:String, delegate: VisionAppDelegate) {
        if #available(iOS 12.0, *), ARFaceTrackingConfiguration.isSupported {
            self.delegate = delegate
            VARequestManager.shared.appToken = token
            VARequestManager.shared.appSecret = secret
        } else {
            self.printAlertNotSupported()
        }
    }
    
    public func startTracking(userToken: String? = nil) {
        if ARFaceTrackingConfiguration.isSupported, let userToken = userToken {
            DispatchQueue.main.async {
                let previousToken = UserDefaults.standard.string(forKey: "VAuserToken")
                UserDefaults.standard.set(userToken, forKey: "VAuserToken")
                self.getUserSession(previousToken)
            }
        } else if ARFaceTrackingConfiguration.isSupported, VASessionManager.shared.currentUser != nil {

            DispatchQueue.main.async {
                self.initScene()
                self.getUserSession()
            }
            
        } else if ARFaceTrackingConfiguration.isSupported {
            DispatchQueue.main.async {
                
                let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? NSLocalizedString("the app", tableName: nil, bundle: Bundle(for: type(of: self)), value: "", comment: "")
                
                let alertController = UIAlertController(title: "VisionApp", message: String(format: NSLocalizedString("Do you have a VisionApp account that you want to link to %@?", bundle: Bundle(for: type(of: self)), comment: ""), appName), preferredStyle: .alert)
                
                let doneAction = UIAlertAction(title: NSLocalizedString("Yes", bundle: Bundle(for: type(of: self)), comment: ""), style: .default, handler: { (_) in
                    let storyboard = UIStoryboard(name: "Main", bundle: Bundle(for: type(of: self)))
                    guard let loginViewController = storyboard.instantiateViewController(withIdentifier: "loginVC") as? VALoginVC else { return }
                    loginViewController.modalPresentationStyle = .formSheet
//                    if #available(iOS 13.0, *) {
//                        loginViewController.isModalInPresentation = true
//                    }
                    UIApplication.shared.windows.last?.rootViewController?.present(loginViewController, animated: true, completion: nil)
                })
                alertController.addAction(doneAction)
                
                let cancelAction = UIAlertAction(title: NSLocalizedString("No", bundle: Bundle(for: type(of: self)), comment: ""), style: .cancel) { (_) in
                    self.delegate?.cancelVALogin()
                }
                alertController.addAction(cancelAction)

                UIApplication.shared.windows.last?.rootViewController?.present(alertController, animated: true, completion: nil)

            }
        } else {
            self.printAlertNotSupported()
        }
    }
    
    func initScene() {
        // HIDDEN VIEW
        let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? NSLocalizedString("the app", tableName: nil, bundle: Bundle(for: type(of: self)), value: "", comment: "")
        self.hiddenView = HiddenView(frame: UIScreen.main.bounds)
        hiddenView!.textLabel.text = String(format: NSLocalizedString("You are too close to the screen.\n\nGet away to continue using %@.", tableName: nil, bundle: Bundle(for: type(of: self)), value: "", comment: ""), appName)
        let topContrain = NSLayoutConstraint(item: self.hiddenView!, attribute: .top, relatedBy: .equal, toItem: UIApplication.shared.windows.last, attribute: .top, multiplier: 1, constant: 0)
        let bottomContrain = NSLayoutConstraint(item: self.hiddenView!, attribute: .bottom, relatedBy: .equal, toItem: UIApplication.shared.windows.last, attribute: .bottom, multiplier: 1, constant: 0)
        let leftContrain = NSLayoutConstraint(item: self.hiddenView!, attribute: .left, relatedBy: .equal, toItem: UIApplication.shared.windows.last, attribute: .left, multiplier: 1, constant: 0)
        let rightContrain = NSLayoutConstraint(item: self.hiddenView!, attribute: .right, relatedBy: .equal, toItem: UIApplication.shared.windows.last, attribute: .right, multiplier: 1, constant: 0)
        UIApplication.shared.windows.last?.addSubview(self.hiddenView!)
        self.hiddenView!.translatesAutoresizingMaskIntoConstraints = false
        UIApplication.shared.windows.last?.addConstraints([topContrain, bottomContrain, leftContrain, rightContrain])
        self.hiddenView!.isHidden = true

        // SCENE VIEW
        self.sceneView = ARSCNView()
        self.sceneView!.delegate = self
        self.sceneView!.session.delegate = self
        self.sceneView!.automaticallyUpdatesLighting = true
        self.selectedVirtualContent = VirtualContentType(rawValue: 0)
        
        NotificationCenter.default.addObserver(self, selector: #selector(appHasComeFromBackground(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        UIApplication.shared.windows.last?.addSubview(self.sceneView!)
        UIApplication.shared.isIdleTimerDisabled = true
        self.resetTracking()
        self.setupEyeNode()
        
    }
    
    func getUserSession(_ previousToken:String? = nil) {
        VARequestManager.shared.getSessionUser { (success, message, user) in
            if let user = user, user.profiles.count > 0 {
                VASessionManager.shared.setUserInfo(user)
                self.currentUser = user
                let profileCode = UserDefaults.standard.integer(forKey: "VAcurrentUserProfileCode")
                if let profile = user.profiles.first(where: {$0.code == profileCode}) {
                    self.currentProfile = profile
                    self.setScene(previousToken, user: user, profile: profile)
                    if let lastSecond = UserDefaults.standard.object(forKey: "initDate\(profile.accountId)") as? Date {
                        self.lastSecond = lastSecond
                    } else {
                        self.lastSecond = Date()
                        UserDefaults.standard.set(self.lastSecond!, forKey: "initDate\(profile.accountId)")
                    }
                    self.checkForDevice(profile: profile)
                } else if user.profiles.count == 1 {
                    let profile = user.profiles[0]
                    UserDefaults.standard.set(profile.code, forKey: "VAcurrentUserProfileCode")
                    self.currentProfile = profile
                    self.setScene(previousToken, user: user, profile: profile)
                    if let lastSecond = UserDefaults.standard.object(forKey: "initDate\(profile.accountId)") as? Date {
                        self.lastSecond = lastSecond
                    } else {
                        self.lastSecond = Date()
                        UserDefaults.standard.set(self.lastSecond!, forKey: "initDate\(profile.accountId)")
                    }
                } else {
                    self.profileSelection(previousToken)
                }
                
            } else if let previousToken = previousToken {
                UserDefaults.standard.set(previousToken, forKey: "VAuserToken")
            }
        }
    }
    
    func setScene(_ previousToken:String? = nil, user:VAUser, profile:VAProfile) {
        self.delegate?.userVAInfo(userToken: "\(user.userCode).\(user.secret)", userName: "\(user.firstname) \(user.lastname)", profileId: profile.code, profileName: profile.name)
        if previousToken != nil {
            self.initScene()
        }
    }
    
    public var profilesNumber: Int {
        get {
            if let user = VisionApp.shared.currentUser {
                return user.profiles.count
            }
            return 0
        }
    }

    public func profileSelection(_ userToken:String? = nil) {
        if let user = self.currentUser {
            if user.profiles.count == 1 {
                let profile = user.profiles[0]
                UserDefaults.standard.set(profile.code, forKey: "VAcurrentUserProfileCode")
                self.currentProfile = profile
                self.setScene(userToken, user: user, profile: profile)
                if let lastSecond = UserDefaults.standard.object(forKey: "initDate\(profile.accountId)") as? Date {
                    self.lastSecond = lastSecond
                } else {
                    self.lastSecond = Date()
                    UserDefaults.standard.set(self.lastSecond!, forKey: "initDate\(profile.accountId)")
                }
            } else if user.profiles.count > 1 {
                let alertController = UIAlertController(title: NSLocalizedString("Select profile", tableName: nil, bundle: Bundle(for: type(of: self)), value: "", comment: ""), message: nil, preferredStyle: .alert)
                for profile in user.profiles {
                    let profileAction = UIAlertAction(title: profile.name, style: .default) { (_) in
                        UserDefaults.standard.set(profile.code, forKey: "VAcurrentUserProfileCode")
                        self.currentProfile = profile
                        self.setScene(userToken, user: user, profile: profile)
                        if let lastSecond = UserDefaults.standard.object(forKey: "initDate\(profile.accountId)") as? Date {
                            self.lastSecond = lastSecond
                        } else {
                            self.lastSecond = Date()
                            UserDefaults.standard.set(self.lastSecond!, forKey: "initDate\(profile.accountId)")
                        }
                    }
                    alertController.addAction(profileAction)
                }
                
                let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", tableName: nil, bundle: Bundle(for: type(of: self)), value: "", comment: ""), style: .cancel) { (_) in
                    self.delegate?.cancelVALogin()
                    self.stopTracking()
                }
                alertController.addAction(cancelAction)
                
                UIApplication.shared.windows.last?.rootViewController?.present(alertController, animated: true, completion: nil)
            }
        }
    }

    func checkForDevice(profile: VAProfile) {
        
        let makeAndModel = UIDevice.current.modelName
        let deviceIsTablet = UIDevice.current.userInterfaceIdiom == .pad
        let deviceSO = "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
        
        var deviceJSON = [
            "deviceIsTablet":deviceIsTablet ? "1" : "0",
            "makeAndModel": makeAndModel,
            "SO": deviceSO,
        ]
        if let deviceIdentifer = UIDevice.current.identifierForVendor?.uuidString {
            deviceJSON["deviceId"] = deviceIdentifer
            if !profile.devices.contains(where: {$0.deviceId == deviceIdentifer}) {
                self.setNewDevice(deviceJSON: deviceJSON, profile: profile)
            } else if let index = profile.devices.firstIndex(where:{$0.deviceId == deviceIdentifer || $0.makeAndModel == makeAndModel}) {
                self.deviceId = profile.devices[index].id
            }
        } else if !profile.devices.contains(where: {$0.makeAndModel == makeAndModel}) {
            self.setNewDevice(deviceJSON: deviceJSON, profile: profile)
        } else if let index = profile.devices.firstIndex(where:{$0.makeAndModel == makeAndModel}) {
            self.deviceId = profile.devices[index].id
        }

    }
    
    func setNewDevice(deviceJSON:[String:Any], profile: VAProfile) {
        VARequestManager.shared.setDevice(parameters: deviceJSON, accountCode: profile.accountId, profileCode: profile.code) { (message, id) in
            if let id = id {
                self.deviceId = id
                let newDevice = VADevice(id: id, makeAndModel: deviceJSON["makeAndModel"] as! String, deviceId: deviceJSON["deviceId"] as? String ?? nil)
                if let index = self.currentUser?.profiles.firstIndex(where:{$0.code == profile.code}) {
                    self.currentUser?.profiles[index].devices.append(newDevice)
                }
            } else {
                print(message)
                
            }
        }
    }
    public func stopTracking() {
        if self.hiddenView != nil {
            self.hiddenView!.removeFromSuperview()
        }
        if self.sceneView != nil {
            self.sceneView!.removeFromSuperview()
        }
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        
        let dict:NSDictionary = UserDefaults.standard.dictionaryRepresentation() as NSDictionary
        for key in dict {
            UserDefaults.standard.removeObject(forKey: key.key as! String)
        }
        UserDefaults.standard.synchronize();

    }

    @objc func appHasComeFromBackground(_ notification: NSNotification) {
        if self.sceneView != nil {
            UIApplication.shared.isIdleTimerDisabled = true
            self.resetTracking()
            self.setupEyeNode()
        }
        
        if let currentProfile = self.currentProfile, let stream = UserDefaults.standard.object(forKey: "stream\(currentProfile.accountId)") as? [[String:Int]], stream.count > 0, let bundleIdentifier = Bundle.main.bundleIdentifier, let timestamp = UserDefaults.standard.object(forKey: "initDate\(currentProfile.accountId)") as? Date, let deviceId = self.deviceId {
            
            let distances = stream.map { (s) -> Int in
                return s["d"] ?? 0
            }
            
            print(timestamp.millisecondsSince1970)
            
            let measurementStream:[String:Any] = [
                "meanDistance": Float(distances.reduce(0, +)) / Float(distances.count),
                "stream": stream,
                "timestamp": timestamp.millisecondsSince1970,
                "userActivity": [[
                    "a": ["p", bundleIdentifier],
                    "t": stream.count
                    ]]
            ]
            
            VARequestManager.shared.sendData(parameters: measurementStream, accountCode: currentProfile.accountId, profileCode: currentProfile.code, deviceCode: deviceId) { (success, message) in
                if success {
                    UserDefaults.standard.set([], forKey: "stream\(currentProfile.accountId)")
                    self.lastSecond = Date()
                    UserDefaults.standard.set(self.lastSecond!, forKey: "initDate\(currentProfile.accountId)")
                } else {
                    print(message)
                    
                }
            }
            
        }
    }

    func resetTracking() {
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        self.sceneView!.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        self.setupEyeNode()
    }

    func setupEyeNode(){
        let eyeGeometry = SCNSphere(radius: 0.005)
        eyeGeometry.materials.first?.diffuse.contents = UIColor.clear
        eyeGeometry.materials.first?.transparency = 1
        
        let node = SCNNode()
        node.geometry = eyeGeometry
        node.eulerAngles.x = -.pi / 2
        node.position.z = 0.1
        
        leftEye = node.clone()
        rightEye = node.clone()
    }
    
    func printAlertNotSupported() {
        print("****************************************************************************************************************************")
        print("*                                                                                                                          *")
        print("*                         IMPORTANT: ARFaceTrackingConfiguration not supported for your device.                            *")
        print("*                                                                                                                          *")
        print("****************************************************************************************************************************")
    }
    
    func printAlertBadRequest() {
        print("****************************************************************************************************************************")
        print("*                                                                                                                          *")
        print("*                                  IMPORTANT: configure token & secret for your app.                                       *")
        print("*                                                                                                                          *")
        print("****************************************************************************************************************************")
    }

    public func displayErrorMessage(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let gotoSettingsAction = UIAlertAction(title: NSLocalizedString("Go to Settings", tableName: nil, bundle: Bundle(for: type(of: self)), value: "", comment: ""), style: .default) { (_) in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        }
        alertController.addAction(gotoSettingsAction)
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Later", tableName: nil, bundle: Bundle(for: type(of: self)), value: "", comment: ""), style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        UIApplication.shared.windows.last?.rootViewController?.present(alertController, animated: true, completion: nil)
    }
    
}

protocol VirtualContentController: ARSCNViewDelegate {
    var contentNode: SCNNode? { get set }
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode?
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor)
}

extension VisionApp: ARSCNViewDelegate {
    
    public func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        currentFaceAnchor = faceAnchor
        
        // If this is the first time with this anchor, get the controller to create content.
        // Otherwise (switching content), will change content when setting `selectedVirtualContent`.
        if node.childNodes.isEmpty, let contentNode = selectedContentController.renderer(renderer, nodeFor: faceAnchor) {
            node.addChildNode(contentNode)
        }
        
        //1. Setup The FaceNode & Add The Eyes
        self.faceNode = node
        self.faceNode.addChildNode(leftEye)
        self.faceNode.addChildNode(rightEye)
        self.faceNode.transform = node.transform
        
        //2. Get The Distance Of The Eyes From The Camera
        trackDistance()
        
        //3. Eyes and jaw
        /*
         let blendShapes = faceAnchor.blendShapes
         let eyeBlinkLeft = blendShapes[.eyeBlinkLeft] as? Float
         let eyeBlinkRight = blendShapes[.eyeBlinkRight] as? Float
         let jawOpen = blendShapes[.jawOpen] as? Float
         */
        
    }
    
    /// - Tag: ARFaceGeometryUpdate
    public func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard anchor == currentFaceAnchor,
            let contentNode = selectedContentController.contentNode,
            contentNode.parent == node
            else { return }
        
        selectedContentController.renderer(renderer, didUpdate: contentNode, for: anchor)
        
        self.faceNode.transform = node.transform
        if let faceAnchor = anchor as? ARFaceAnchor {
            self.currentFaceAnchor = faceAnchor
        }
        
        //2. Check We Have A Valid ARFaceAnchor
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        
        //3. Update The Transform Of The Left & Right Eyes From The Anchor Transform
        if #available(iOS 12.0, *) {
            leftEye.simdTransform = faceAnchor.leftEyeTransform
            rightEye.simdTransform = faceAnchor.rightEyeTransform
        }
        
        //4. Get The Distance Of The Eyes From The Camera
        trackDistance()
    }
    
    func trackDistance(){
        
        DispatchQueue.main.async {
            
            //4. Get The Distance Of The Eyes From The Camera
            let leftEyeDistanceFromCamera = self.leftEye.worldPosition - SCNVector3Zero
            let rightEyeDistanceFromCamera = self.rightEye.worldPosition - SCNVector3Zero
            
            //5. Calculate The Average Distance Of The Eyes To The Camera
            let averageDistance = (leftEyeDistanceFromCamera.length() + rightEyeDistanceFromCamera.length()) / 2
            
            let averageDistanceCM = Int(round(averageDistance * 100))
            if averageDistanceCM <= 30 {
                self.hiddenView?.isHidden = false
            } else {
                self.hiddenView?.isHidden = true
            }
            
            //6. Print distance
//            self.distanceLabel.text = "\(averageDistanceCM) cm"

            // 7. Light
//            if let estimate = self.sceneView!.session.currentFrame?.lightEstimate {
//                let intensityRounded = Int(round(estimate.ambientIntensity)) // lumens
//                let colorRounded = Int(round(estimate.ambientColorTemperature)) // degrees Kelvin
//                self.intensityLabel.text = "\(intensityRounded) lm"
//                self.colorLabel.text = "\(colorRounded) K"
//            }
            
            // 8. IPD
//            if #available(iOS 12.0, *) {
//                if let anchor = self.currentFaceAnchor {
//                    let leftEyePosition = SCNVector3(anchor.leftEyeTransform.columns.3.x, anchor.leftEyeTransform.columns.3.y, anchor.leftEyeTransform.columns.3.z)
//                    let rightEyePosition = SCNVector3(anchor.rightEyeTransform.columns.3.x, anchor.rightEyeTransform.columns.3.y, anchor.rightEyeTransform.columns.3.z)
//                    let d = distance(float3(leftEyePosition), float3(rightEyePosition)) * 1000
//                    let lengthTD = String(format: "%.2f", ceil(d*100)/100)
//                    self.ipdLabel.text = "IPD: \(lengthTD) mm"
//                } else {
//                    let lengthMM = distance(float3(self.leftEye.position), float3(self.rightEye.position)) * 1000
//                    let lengthTD = String(format: "%.2f", ceil(lengthMM*100)/100)
//                    self.ipdLabel.text = "IPD: \(lengthTD) mm"
//                }
//            }
            
            
            // 9. Angles
//            let nodeRotation = self.faceNode.eulerAngles
//            let x = Int(round(nodeRotation.x * 180 / .pi))
//            let y = Int(round(nodeRotation.y * 180 / .pi))
//            let z = Int(round(nodeRotation.z * 180 / .pi))
//            self.xAngleLabel.text = "x: \(x)º"
//            self.yAngleLabel.text = "y: \(y)º"
//            self.zAngleLabel.text = "z: \(z)º"
            
            if let currentProfile = self.currentProfile, let initDate = UserDefaults.standard.object(forKey: "initDate\(currentProfile.accountId)") as? Date, let lastSecond = self.lastSecond, let estimate = self.sceneView?.session.currentFrame?.lightEstimate {
                let currentDate = Date()
                let distanceMM = Int(round(averageDistance * 1000))
                let light = Int(round(estimate.ambientIntensity * 100))
                let elapsed = Int(currentDate.timeIntervalSince(initDate))
                let lastElapsed = Int(lastSecond.timeIntervalSince(initDate))
                if elapsed > lastElapsed {
                    self.lastSecond = currentDate
                    let currentStream = [
                        "d": distanceMM,
                        "l": light,
                        "t": elapsed
                    ]
                    var stream = UserDefaults.standard.object(forKey: "stream\(currentProfile.accountId)") as? [[String:Int]] ?? []
                    stream.append(currentStream)
                    UserDefaults.standard.set(stream, forKey: "stream\(currentProfile.accountId)")
                    
                }
                
            }
            
        }
    }
    
}

extension VisionApp: ARSessionDelegate {
    
    public func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedRecoverySuggestion
        ]
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        
        DispatchQueue.main.async {
            self.displayErrorMessage(title: "VisionApp", message: errorMessage)
        }
    }
    
}

extension SCNMatrix4 {
    /**
     Create a 4x4 matrix from CGAffineTransform, which represents a 3x3 matrix
     but stores only the 6 elements needed for 2D affine transformations.
     
     [ a  b  0 ]     [ a  b  0  0 ]
     [ c  d  0 ]  -> [ c  d  0  0 ]
     [ tx ty 1 ]     [ 0  0  1  0 ]
     .               [ tx ty 0  1 ]
     
     Used for transforming texture coordinates in the shader modifier.
     (Needs to be SCNMatrix4, not SIMD float4x4, for passing to shader modifier via KVC.)
     */
    init(_ affineTransform: CGAffineTransform) {
        self.init()
        m11 = Float(affineTransform.a)
        m12 = Float(affineTransform.b)
        m21 = Float(affineTransform.c)
        m22 = Float(affineTransform.d)
        m41 = Float(affineTransform.tx)
        m42 = Float(affineTransform.ty)
        m33 = 1
        m44 = 1
    }
}

extension SCNReferenceNode {
    convenience init(named resourceName: String, loadImmediately: Bool = true) {
        let url = Bundle(for: VisionApp.self).url(forResource: resourceName, withExtension: "scn", subdirectory: "Models.scnassets")!
        self.init(url: url)!
        if loadImmediately {
            self.load()
        }
    }
}

extension SCNVector3 {
    
    ///Get The Length Of Our Vector
    func length() -> Float { return sqrtf(x * x + y * y + z * z) }
    
    ///Allow Us To Subtract Two SCNVector3's
    static func - (l: SCNVector3, r: SCNVector3) -> SCNVector3 { return SCNVector3Make(l.x - r.x, l.y - r.y, l.z - r.z) }
    
}

extension Date {
    var millisecondsSince1970:Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
    
    init(milliseconds:Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}

extension UIDevice {
    
    /// pares the deveice name as the standard name
    var modelName: String {
        
        #if targetEnvironment(simulator)
        let identifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"]!
        #else
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8 , value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        #endif
        
        func mapToDevice(identifier: String) -> String { // swiftlint:disable:this cyclomatic_complexity
            switch identifier {
            case "iPod5,1":                                 return "iPod Touch 5"
            case "iPod7,1":                                 return "iPod Touch 6"
            case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
            case "iPhone4,1":                               return "iPhone 4s"
            case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
            case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
            case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
            case "iPhone7,2":                               return "iPhone 6"
            case "iPhone7,1":                               return "iPhone 6 Plus"
            case "iPhone8,1":                               return "iPhone 6s"
            case "iPhone8,2":                               return "iPhone 6s Plus"
            case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
            case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
            case "iPhone8,4":                               return "iPhone SE"
            case "iPhone10,1", "iPhone10,4":                return "iPhone 8"
            case "iPhone10,2", "iPhone10,5":                return "iPhone 8 Plus"
            case "iPhone10,3", "iPhone10,6":                return "iPhone X"
            case "iPhone11,2":                              return "iPhone XS"
            case "iPhone11,4", "iPhone11,6":                return "iPhone XS Max"
            case "iPhone11,8":                              return "iPhone XR"
            case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
            case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
            case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
            case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
            case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
            case "iPad6,11", "iPad6,12":                    return "iPad 5"
            case "iPad7,5", "iPad7,6":                      return "iPad 6"
            case "iPad11,4", "iPad11,5":                    return "iPad Air (3rd generation)"
            case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
            case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
            case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
            case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
            case "iPad11,1", "iPad11,2":                    return "iPad Mini 5"
            case "iPad6,3", "iPad6,4":                      return "iPad Pro (9.7-inch)"
            case "iPad6,7", "iPad6,8":                      return "iPad Pro (12.9-inch)"
            case "iPad7,1", "iPad7,2":                      return "iPad Pro (12.9-inch) (2nd generation)"
            case "iPad7,3", "iPad7,4":                      return "iPad Pro (10.5-inch)"
            case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":return "iPad Pro (11-inch)"
            case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":return "iPad Pro (12.9-inch) (3rd generation)"
            case "AppleTV5,3":                              return "Apple TV"
            case "AppleTV6,2":                              return "Apple TV 4K"
            case "AudioAccessory1,1":                       return "HomePod"
            case "i386", "x86_64":                          return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "iOS"))"
            default:                                        return identifier
            }
        }
        
        return "Apple \(mapToDevice(identifier: identifier))"
    }
    
}

enum VirtualContentType: Int {
    case transforms
    
    func makeController() -> VirtualContentController {
        return TransformVisualization()
    }
}

class TransformVisualization: NSObject, VirtualContentController {
    
    var contentNode: SCNNode?
    
    // Load multiple copies of the axis origin visualization for the transforms this class visualizes.
    lazy var rightEyeNode = SCNReferenceNode(named: "coordinateOrigin")
    lazy var leftEyeNode = SCNReferenceNode(named: "coordinateOrigin")
    
    /// - Tag: ARNodeTracking
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        // This class adds AR content only for face anchors.
        guard anchor is ARFaceAnchor else { return nil }
        
        // Load an asset from the app bundle to provide visual content for the anchor.
        contentNode = SCNReferenceNode(named: "coordinateOrigin")
        
        // Add content for eye tracking in iOS 12.
        self.addEyeTransformNodes()
        
        // Provide the node to ARKit for keeping in sync with the face anchor.
        return contentNode
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor
            else { return }
        
        if #available(iOS 12.0, *) {
            rightEyeNode.simdTransform = faceAnchor.rightEyeTransform
            leftEyeNode.simdTransform = faceAnchor.leftEyeTransform
        }
    }
    
    func addEyeTransformNodes() {
        guard let anchorNode = contentNode else { return }
        
        // Scale down the coordinate axis visualizations for eyes.
        rightEyeNode.simdPivot = float4x4(diagonal: SIMD4(3, 3, 3, 1))
        leftEyeNode.simdPivot = float4x4(diagonal: SIMD4(3, 3, 3, 1))
        
        anchorNode.addChildNode(rightEyeNode)
        anchorNode.addChildNode(leftEyeNode)
        
    }
    
}
