//
//  VASessionManager.swift
//  VisionApp
//
//  Created by Emilio Cubo Ruiz on 04/07/2019.
//  Copyright © 2019 VisionApp. All rights reserved.
//

import UIKit

class VASessionManager: NSObject {

    static let shared = VASessionManager()

    var currentUser:VAUser? {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: "VAuser"), let user = try? decoder.decode(VAUser.self, from: data) {
            return user
        }
        return nil
    }
    
    func setUserInfo(_ user:VAUser) {
        UserDefaults.standard.set(user.userCode, forKey: "VAcurrentUserID")
        UserDefaults.standard.set(user.secret, forKey: "VAcurrentUserCode")
        UserDefaults.standard.set("\(user.userCode).\(user.secret)", forKey: "VAuserToken")

        if user.profiles.count == 1 {
            UserDefaults.standard.set(user.profiles[0].code, forKey: "VAcurrentUserProfileCode")
        }
        
        do {
            let data = try JSONEncoder().encode(user)
            UserDefaults.standard.set(data, forKey: "VAuser")
        } catch {
            print(error)
        }
    }

}
