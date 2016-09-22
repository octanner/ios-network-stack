//
//  OAuth2Client.swift
//  NetworkStack
//
//  Created by Tim on 2/24/16.
//  Copyright © 2016 OC Tanner. All rights reserved.
//

import Foundation
import Marshal
import SimpleKeychain

struct OAuth2Client: Unmarshaling {
    
    let id: String
    let secret: String
    
    private static let keychain = Keychain()
    private static let idKey = "client_id"
    private static let secretKey = "client_secret"
    
    
    init(id: String, secret: String) {
        self.id = id
        self.secret = secret
    }
    
    init(object: MarshaledObject) throws {
        self.id = try object <| OAuth2Client.idKey
        self.secret = try object <| OAuth2Client.secretKey
    }
    
    init(key: String) throws {
        let dictionary: MarshalDictionary = try OAuth2Client.keychain.valueForKey(OAuth2Client.clientKey(key))
        try self.init(object: dictionary)
    }
    
    func lock(with key: String) throws {
        let clientValues: NSDictionary = [
            OAuth2Client.idKey: id as AnyObject,
            OAuth2Client.secretKey: secret as AnyObject
        ]
        try OAuth2Client.keychain.set(clientValues, forKey: OAuth2Client.clientKey(key))
    }
    
    static func delete(with key: String) {
        OAuth2Client.keychain.deleteValue(forKey: clientKey(key))
    }
    
    private static func clientKey(_ key: String) -> String {
        return "\(key).oauthClient"
    }
    
}
