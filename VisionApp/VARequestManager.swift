//
//  VARequestManager.swift
//  VisionApp
//
//  Created by Emilio Cubo Ruiz on 04/09/2019.
//  Copyright © 2019 VisionApp. All rights reserved.
//

import Foundation
import SystemConfiguration

class VARequestManager: NSObject {
    
    static let shared = VARequestManager()
    private let baseURL = "https://vision-app.webintra.net/api/VisionApp/"
    private let decoder = JSONDecoder()
    var appToken = ""
    var appSecret = ""

    func getData(_ data:[String:Any]) -> Data? {
        decoder.dateDecodingStrategy = .formatted(DateFormatter.yyyyMMdd)
        do {
            return try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
        } catch {
            return nil
        }
    }

    func getArrayData(data:[[String:Any]]) -> [Data]? {
        do {
            let result = try data.map({ (data) -> Data in
                return try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            })
            return result
        } catch {
            return nil
        }
    }
    
    func signInUser(_ email:String?, password:String?, callBack:@escaping (Bool, String, VAUser?) -> ()) {
        let urlString:String = "\(self.baseURL)accounts/login"
        let url = URL(string:urlString.trimmingCharacters(in: .whitespaces))
        
        if appToken != "", appSecret != "", let email = email, let password = password {
            let dictFromJSON:[String:Any] = [
                "email"     :   email,
                "password"  :   password
            ]
            
            var request = URLRequest(url: url!)
            request.httpMethod = "POST"
            request.httpBody = dictFromJSON.percentEscaped().data(using: .utf8)
//            let jsonObject = try! JSONSerialization.data(withJSONObject:dictFromJSON, options: [])
//            request.httpBody = jsonObject
            request.addValue(self.appToken, forHTTPHeaderField: "Token")
            request.addValue(self.appSecret, forHTTPHeaderField: "Secret")
            request.addValue("ios", forHTTPHeaderField: "API-apptype")
            
            if let userToken = UserDefaults.standard.string(forKey: "VAuserToken") {
                request.addValue(userToken, forHTTPHeaderField: "SESSION-GI")
            } else if let userId =  UserDefaults.standard.string(forKey: "VAcurrentUserID"), let userSecret = UserDefaults.standard.string(forKey: "VAcurrentUserCode") {
                request.addValue("\(userId).\(userSecret)", forHTTPHeaderField: "SESSION-GI")
            }

            switch Reach().connectionStatus() {
            case .unknown, .offline:
                callBack(false, "No internet connection", nil)
            case .online(.wwan), .online(.wiFi):
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    DispatchQueue.main.async(execute: { () -> Void in
                        if let error = error {
                            callBack(false, error.localizedDescription, nil)
                        } else if let httpResponse = response as? HTTPURLResponse {
                            switch httpResponse.statusCode {
                            case 200:
                                if let data = data {
                                    do {
                                        if let result = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] {
                                            if let data = self.getData(result), let user = try? self.decoder.decode(VAUser.self, from: data) {
                                                callBack(true, "done", user)
                                            } else if let message = result["info"] as? String {
                                                callBack(false, message, nil)
                                            } else {
                                                callBack(false, "Server error", nil)
                                            }
                                        } else {
                                            callBack(false, "Server error", nil)
                                        }
                                    } catch {
                                        callBack(false, error.localizedDescription, nil)
                                    }
                                } else {
                                    callBack(false, "Server error", nil)
                                }
                            default:
                                callBack(false, "Server error", nil)
                            }
                        } else {
                            callBack(false, "Server error", nil)
                        }
                    })
                }
                task.resume()
            }
            
        } else {
            callBack(false, "Data error", nil)
        }

    }
    
    func recoveryPassword(email:String, callBack:@escaping (Bool, String) -> ()) {
        let urlString:String = "\(self.baseURL)users/recoveryPassword/\(email)"
        let url = URL(string:urlString.trimmingCharacters(in: .whitespaces))
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        request.addValue(self.appToken, forHTTPHeaderField: "Token")
        request.addValue(self.appSecret, forHTTPHeaderField: "Secret")
        request.addValue("ios", forHTTPHeaderField: "API-apptype")
        
        if let userToken = UserDefaults.standard.string(forKey: "VAuserToken") {
            request.addValue(userToken, forHTTPHeaderField: "SESSION-GI")
        } else if let userId =  UserDefaults.standard.string(forKey: "VAcurrentUserID"), let userSecret = UserDefaults.standard.string(forKey: "VAcurrentUserCode") {
            request.addValue("\(userId).\(userSecret)", forHTTPHeaderField: "SESSION-GI")
        }

        switch Reach().connectionStatus() {
        case .unknown, .offline:
            callBack(false, "No internet connection")
        case .online(.wwan), .online(.wiFi):
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async(execute: { () -> Void in
                    if let error = error {
                        callBack(false, error.localizedDescription)
                    } else if let httpResponse = response as? HTTPURLResponse {
                        switch httpResponse.statusCode {
                        case 200:
                            if data != nil {
                                callBack(true, "done")
                            } else {
                                callBack(false, "Server error")
                            }
                        default:
                            callBack(false, "Server error")
                        }
                    } else {
                        callBack(false, "Server error")
                    }
                })
            }
            task.resume()
        }
    }
    
    func getSessionUser(callBack:@escaping (Bool, String, VAUser?) -> ()) {
        let urlString:String = "\(self.baseURL)accounts/session"
        let url = URL(string:urlString.trimmingCharacters(in: .whitespaces))
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        request.addValue(self.appToken, forHTTPHeaderField: "Token")
        request.addValue(self.appSecret, forHTTPHeaderField: "Secret")
        request.addValue("ios", forHTTPHeaderField: "API-apptype")
        
        if let userToken = UserDefaults.standard.string(forKey: "VAuserToken") {
            request.addValue(userToken, forHTTPHeaderField: "SESSION-GI")
        } else if let userId =  UserDefaults.standard.string(forKey: "VAcurrentUserID"), let userSecret = UserDefaults.standard.string(forKey: "VAcurrentUserCode") {
            request.addValue("\(userId).\(userSecret)", forHTTPHeaderField: "SESSION-GI")
        }

        switch Reach().connectionStatus() {
        case .unknown, .offline:
            callBack(false, "No internet connection", nil)
        case .online(.wwan), .online(.wiFi):
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async(execute: { () -> Void in
                    if let error = error {
                        callBack(false, error.localizedDescription, nil)
                    } else if let httpResponse = response as? HTTPURLResponse {
                        switch httpResponse.statusCode {
                        case 200:
                            if let data = data {
                                do {
                                    if let result = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] {
                                        if let data = self.getData(result), let user = try? self.decoder.decode(VAUser.self, from: data) {
                                            callBack(true, "done", user)
                                        } else if let message = result["info"] as? String {
                                            callBack(false, message, nil)
                                        } else {
                                            callBack(false, "Server error", nil)
                                        }
                                    } else {
                                        callBack(false, "Server error", nil)
                                    }
                                } catch {
                                    callBack(false, error.localizedDescription, nil)
                                }
                            } else {
                                callBack(false, "Server error", nil)
                            }
                        default:
                            callBack(false, "Server error", nil)
                        }
                    } else {
                        callBack(false, "Server error", nil)
                    }
                })
            }
            task.resume()
        }
    }
    
    func setDevice(parameters:[String:Any], accountCode:Int, profileCode:Int, callBack:@escaping (String, Int?) -> ()) {
        // let urlString:String = "\(self.baseURL)accounts/\(accountCode)/profile/\(profileCode)/device"
        let urlString:String = "\(self.baseURL)profile/\(profileCode)/device"
        let url = URL(string:urlString.trimmingCharacters(in: .whitespaces))
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        let jsonObject = try! JSONSerialization.data(withJSONObject:parameters, options: [])
        request.httpBody = jsonObject
        request.addValue(self.appToken, forHTTPHeaderField: "Token")
        request.addValue(self.appSecret, forHTTPHeaderField: "Secret")
        request.addValue("ios", forHTTPHeaderField: "API-apptype")
        
        if let userToken = UserDefaults.standard.string(forKey: "VAuserToken") {
            request.addValue(userToken, forHTTPHeaderField: "SESSION-GI")
        } else if let userId =  UserDefaults.standard.string(forKey: "VAcurrentUserID"), let userSecret = UserDefaults.standard.string(forKey: "VAcurrentUserCode") {
            request.addValue("\(userId).\(userSecret)", forHTTPHeaderField: "SESSION-GI")
        }

        switch Reach().connectionStatus() {
        case .unknown, .offline:
            callBack("No internet connection", nil)
        case .online(.wwan), .online(.wiFi):
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async(execute: { () -> Void in
                    if let error = error {
                        callBack(error.localizedDescription, nil)
                    } else if let httpResponse = response as? HTTPURLResponse {
                        switch httpResponse.statusCode {
                        case 200:
                            if let data = data {
                                do {
                                    if let result = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] {
                                        if let data = self.getData(result), let device = try? self.decoder.decode(VADevice.self, from: data) {
                                            callBack("done", device.code)
                                        } else if let message = result["info"] as? String {
                                            callBack(message, nil)
                                        } else {
                                            callBack("Server error", nil)
                                        }
                                    } else {
                                        callBack("Server error", nil)
                                    }
                                } catch {
                                    callBack(error.localizedDescription, nil)
                                }
                            } else {
                                callBack("Server error", nil)
                            }
                        default:
                            callBack("Server error", nil)
                        }
                    } else {
                        callBack("Server error", nil)
                    }
                })
            }
            task.resume()
        }
        
    }

    func getConfiguration(for profile:VAProfile, callBack:@escaping (Bool, String, [VAConfiguration]?) -> ()) {
        // let urlString:String = "\(self.baseURL)accounts/\(profile.accountId)/profiles/\(profile.code)/configuration"
        let urlString:String = "\(self.baseURL)profiles/\(profile.code)/configuration"
        let url = URL(string:urlString.trimmingCharacters(in: .whitespaces))
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        request.addValue(self.appToken, forHTTPHeaderField: "Token")
        request.addValue(self.appSecret, forHTTPHeaderField: "Secret")
        request.addValue("ios", forHTTPHeaderField: "API-apptype")
        
        if let userToken = UserDefaults.standard.string(forKey: "UserToken") {
            request.addValue(userToken, forHTTPHeaderField: "SESSION-GI")
        } else if let userId =  UserDefaults.standard.string(forKey: "currentUserID"), let userSecret = UserDefaults.standard.string(forKey: "currentUserCode") {
            request.addValue("\(userId).\(userSecret)", forHTTPHeaderField: "SESSION-GI")
        }
        
        switch Reach().connectionStatus() {
        case .unknown, .offline:
            callBack(false, "No internet connection", nil)
        case .online(.wwan), .online(.wiFi):
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async(execute: { () -> Void in
                    if let error = error {
                        callBack(false, error.localizedDescription, nil)
                    } else if let httpResponse = response as? HTTPURLResponse {
                        switch httpResponse.statusCode {
                        case 200:
                            if let data = data {
                                do {
                                    if let result = try JSONSerialization.jsonObject(with: data, options: []) as? [[String:AnyObject]] {
                                        if let data = self.getArrayData(data: result) {
                                            let configurations = data.compactMap { (configurationData) -> VAConfiguration? in
                                                if let configuration = try? self.decoder.decode(VAConfiguration.self, from: configurationData) {
                                                    return configuration
                                                }
                                                return nil
                                            }
                                            callBack(true, "done", configurations)
                                        } else {
                                            callBack(false, "Server error", nil)
                                        }
                                    } else {
                                        callBack(false, "Server error", nil)
                                    }
                                } catch {
                                    callBack(false, error.localizedDescription, nil)
                                }
                            } else {
                                callBack(false, "Server error", nil)
                            }
                        default:
                            callBack(false, "Server error", nil)
                        }
                    } else {
                        callBack(false, "Server error", nil)
                    }
                })
            }
            task.resume()
        }
    }
    
    func sendData(parameters:[String:Any], accountCode:Int, profileCode:Int, deviceCode:Int, callBack:@escaping (Bool, String) -> ()) {
        // let urlString:String = "\(self.baseURL)accounts/\(accountCode)/profiles/\(profileCode)/devices/\(deviceCode)/data"
        let urlString:String = "\(self.baseURL)profiles/\(profileCode)/devices/\(deviceCode)/data"
        let url = URL(string:urlString.trimmingCharacters(in: .whitespaces))
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        let jsonObject = try! JSONSerialization.data(withJSONObject:parameters, options: [])
        request.httpBody = jsonObject
        request.addValue(self.appToken, forHTTPHeaderField: "Token")
        request.addValue(self.appSecret, forHTTPHeaderField: "Secret")
        request.addValue("ios", forHTTPHeaderField: "API-apptype")
        
        if let userToken = UserDefaults.standard.string(forKey: "VAuserToken") {
            request.addValue(userToken, forHTTPHeaderField: "SESSION-GI")
        } else if let userId =  UserDefaults.standard.string(forKey: "VAcurrentUserID"), let userSecret = UserDefaults.standard.string(forKey: "VAcurrentUserCode") {
            request.addValue("\(userId).\(userSecret)", forHTTPHeaderField: "SESSION-GI")
        }

        switch Reach().connectionStatus() {
        case .unknown, .offline:
            callBack(false, "No internet connection")
        case .online(.wwan), .online(.wiFi):
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async(execute: { () -> Void in
                    if let error = error {
                        print(error.localizedDescription)
                        
                        callBack(false, error.localizedDescription)
                    } else if let httpResponse = response as? HTTPURLResponse {
                        switch httpResponse.statusCode {
                        case 200:
                            callBack(true, "done")
                        default:
                            callBack(false, "Server error")
                        }
                    } else {
                        callBack(false, "Server error")
                    }
                })
            }
            task.resume()
        }
    }

}

let ReachabilityStatusChangedNotification = "ReachabilityStatusChangedNotification"

class HTTPManager: NSObject {
    
    // MARK: - CheckConnection
    class func isConnectedToNetwork() -> Bool {
        let status = Reach().connectionStatus()
        switch status {
        case .unknown, .offline:
            return false;
        case .online(.wwan), .online(.wiFi):
            return true;
        }
    }
    
}



// MARK: - Check For Status Network
enum ReachabilityType: CustomStringConvertible {
    case wwan
    case wiFi
    
    var description: String {
        switch self {
        case .wwan: return "WWAN"
        case .wiFi: return "WiFi"
        }
    }
}

enum ReachabilityStatus: CustomStringConvertible  {
    case offline
    case online(ReachabilityType)
    case unknown
    
    var description: String {
        switch self {
        case .offline: return "Offline"
        case .online(let type): return "Online (\(type))"
        case .unknown: return "Unknown"
        }
    }
}

class Reach {
    
    func connectionStatus() -> ReachabilityStatus {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }        }) else {
                return .unknown
        }
        
        var flags : SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return .unknown
        }
        
        return ReachabilityStatus(reachabilityFlags: flags)
    }
    
    func monitorReachabilityChanges() {
        let host = "google.com"
        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        let reachability = SCNetworkReachabilityCreateWithName(nil, host)!
        
        SCNetworkReachabilitySetCallback(reachability, { (_, flags, _) in
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: ReachabilityStatusChangedNotification), object: nil)
        }, &context)
        
        SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
    }
    
}

extension ReachabilityStatus {
    fileprivate init(reachabilityFlags flags: SCNetworkReachabilityFlags) {
        let connectionRequired = flags.contains(.connectionRequired)
        let isReachable = flags.contains(.reachable)
        let isWWAN = flags.contains(.isWWAN)
        
        if !connectionRequired && isReachable {
            if isWWAN {
                self = .online(.wwan)
            } else {
                self = .online(.wiFi)
            }
        } else {
            self =  .offline
        }
    }
}

extension Dictionary {
    func percentEscaped() -> String {
        return map { (key, value) in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            return escapedKey + "=" + escapedValue
            }
            .joined(separator: "&")
    }
}

extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}

extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()
}
