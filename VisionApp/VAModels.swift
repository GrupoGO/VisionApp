//
//  VAModels.swift
//  VisionApp
//
//  Created by Emilio Cubo Ruiz on 04/09/2019.
//  Copyright © 2019 VisionApp. All rights reserved.
//

import UIKit

struct VAUser: Codable {
    
        enum CodingKeys: String, CodingKey {
            case code
            case userCode
            case firstname
            case lastname
            case email
            case avatar
            case secret
            case profiles
        }

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            code = try values.decode(Int.self, forKey: .code)
            userCode = try values.decode(Int.self, forKey: .userCode)
            firstname = try values.decode(String.self, forKey: .firstname)
            lastname = try values.decode(String.self, forKey: .lastname)
            email = try values.decode(String.self, forKey: .email)
            avatar = try values.decode(URL.self, forKey: .avatar)
            secret = try values.decode(String.self, forKey: .secret)

            let currentCode = self.code
            var userProfiles = try values.decode([VAProfile].self, forKey: .profiles).sorted(by: {$0.code < $1.code})
            let uniqueSupervisor = userProfiles.filter({$0.supervisors.count == 1})
            if let currentProfile = uniqueSupervisor.first(where: {$0.code > currentCode}), let index = userProfiles.firstIndex(where: {$0.code == currentProfile.code}) {
                userProfiles.insert(userProfiles.remove(at: index), at: 0)
            }
            
            profiles = userProfiles

        }
        
        let code: Int
        let userCode: Int
        let firstname: String
        let lastname: String
        let email: String
        let avatar: URL
        let secret: String
        var profiles: [VAProfile]
}

struct VAProfile: Codable {
    
    let code: Int
    let accountId: Int
    var name: String
    var avatar: URL
    let email: String?
    let center: VATag?
    var alias: String?
    var birthday: Date?
    var gender: VATag?
    let observations: String?
    let refraction: VARefraction?
    var ethnicity: VATag?
    var supervisors: [VASupervisor]
    var protection:VATag
    var licenses: [VALicense]
    // var average:VAAverage?
    var devices: [VADevice]
    let hash: String?

    enum CodingKeys: String, CodingKey {
        case code
        case accountId
        case name
        case avatar
        case center
        case alias
        case birthday
        case gender
        case observations
        case refraction
        case ethnicity
        case supervisors
        case protection
        case email
        case licenses
        // case average
        case devices
        case hash
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        self.code = try values.decode(Int.self, forKey: .code)
        self.accountId = try values.decode(Int.self, forKey: .accountId)
        self.name = try values.decode(String.self, forKey: .name)
        
        do {
            self.avatar = try values.decode(URL.self, forKey: .avatar)
        } catch {
            self.avatar = URL(string: "https://webintra.net/services/user/avatar/default.png")!
        }

        do {
            self.hash = try values.decode(String.self, forKey: .hash)
        } catch {
            self.hash = nil
        }

        do {
            self.center = try values.decode(VATag.self, forKey: .center)
        } catch {
            self.center = nil
        }
        
        do {
            self.alias = try values.decode(String.self, forKey: .alias)
        } catch {
            self.alias = nil
        }
        
        do {
            self.birthday = try values.decode(Date.self, forKey: .birthday)
        } catch {
            self.birthday = nil
        }
        
        do {
            self.gender = try values.decode(VATag.self, forKey: .gender)
        } catch {
            self.gender = nil
        }
        
        do {
            self.observations = try values.decode(String.self, forKey: .observations)
        } catch {
            self.observations = nil
        }
        
        do {
            self.refraction = try values.decode(VARefraction.self, forKey: .refraction)
        } catch {
            self.refraction = nil
        }
        
        do {
            self.ethnicity = try values.decode(VATag.self, forKey: .ethnicity)
        } catch {
            self.ethnicity = nil
        }

        do {
            self.supervisors = try values.decode([VASupervisor].self, forKey: .supervisors)
        } catch {
            self.supervisors = []
        }

        do {
            self.protection = try values.decode(VATag.self, forKey: .protection)
        } catch {
            self.protection = VATag(id: 21226471, name: "off")
        }

        do {
            self.devices = try values.decode([VADevice].self, forKey: .devices)
        } catch {
            self.devices = []
        }
        
//        do {
//            self.average = try values.decode(VAAverage.self, forKey: .average)
//        } catch {
//            self.average = nil
//        }

        do {
            self.email = try values.decode(String.self, forKey: .email)
        } catch {
            self.email = nil
        }
        
        do {
            self.licenses = try values.decode([VALicense].self, forKey: .licenses)
        } catch {
            self.licenses = []
        }
        
    }
    
}

struct VASupervisor: Codable {
    let code: Int
    let email: String
}

struct VALicense: Codable {
    
    enum CodingKeys: String, CodingKey {
        case code
        case profileId
        case centerId
        case status
        case accepted
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        self.code = try values.decode(Int.self, forKey: .code)
        self.profileId = try values.decode(Int.self, forKey: .profileId)
        self.centerId = try values.decode(Int.self, forKey: .centerId)
        self.status = try values.decode(Int.self, forKey: .status)
        
        do {
            self.accepted = try values.decode(Bool.self, forKey: .accepted)
        } catch {
            self.accepted = false
        }
        
    }

    var code: Int
    var profileId: Int
    var centerId: Int
    var status: Int
    var accepted: Bool
    
}

struct VATag: Codable {
    
    var id: Int
    var name: String
    
}

struct VARefraction: Codable {
    
    var od: VAOculus
    var os: VAOculus
    
}

struct VAOculus: Codable {
    
    var sphere: String
    var cylinder: String
    var axis: String
    var avg: String
    
}

struct VADevice: Codable {
    
    var code: Int
    var makeAndModel: String
    var deviceIsTablet: Bool
    var deviceId: String?
    
    init(code:Int, makeAndModel:String, deviceIsTablet:Bool, deviceId:String?) {
        self.code = code
        self.makeAndModel = makeAndModel
        self.deviceIsTablet = deviceIsTablet
        self.deviceId = deviceId
    }
    
}

struct VAConfiguration: Codable {
    
    let staffCode: Int
    let distanceToDevice: Int
    let maxLux: Int
    let minLux: Int
    let maxDayTime: Int
    
}
