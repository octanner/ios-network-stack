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
    
    // MARK: - Error
    
    enum OAuth2ClientError: Error {
        case typeMismatch
    }
    
    
    // MARK: - Internal properties
    
    let id: String
    let secret: String
    
    
    // MARK: - Private properties
    
    fileprivate static let keychain = Keychain()
    
    
    // MARK: - Constants
    
    fileprivate static let idKey = "client_id"
    fileprivate static let secretKey = "client_secret"
    
    
    // MARK: - Initializers
    
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
    
    
    // MARK: - Public functions
    
    func lock(_ key: String) throws {
        let clientValues: NSDictionary = [
            OAuth2Client.idKey: id as AnyObject,
            OAuth2Client.secretKey: secret as AnyObject
        ]
        try OAuth2Client.keychain.set(clientValues, forKey: OAuth2Client.clientKey(key))
    }
    
    static func delete(_ key: String) {
        OAuth2Client.keychain.deleteValue(forKey: clientKey(key))
    }
    
}


// MARK: - Private helper functions

private extension OAuth2Client {
    
    static func clientKey(_ key: String) -> String {
        return "\(key).oauthClient"
    }
    
}
