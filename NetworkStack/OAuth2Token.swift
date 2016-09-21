//
//  OAuth2Token.swift
//  NetworkStack
//
//  Created by Ben Norris on 2/11/16.
//  Copyright © 2016 OC Tanner. All rights reserved.
//

import Foundation
import Marshal
import SimpleKeychain

struct OAuth2Token: Unmarshaling {

    // MARK: - Error

    enum OAuth2TokenError: Error {
        case typeMismatch
    }


    // MARK: - Internal properties
    
    let accessToken: String
    let expiresAt: Date
    let refreshToken: String?
    
    
    // MARK: - Private properties

    fileprivate static let keychain = Keychain()
    
    
    // MARK: - Constants
    
    fileprivate static let accessTokenKey = "access_token"
    fileprivate static let expiresAtKey = "expires_at"
    fileprivate static let expiresInKey = "expires_in"
    fileprivate static let refreshTokenKey = "refresh_token"
    
    
    // MARK: - Initializers
    
    init(accessToken: String, expiresAt: Date = Date.distantFuture, refreshToken: String? = nil) {
        self.accessToken = accessToken
        self.expiresAt = expiresAt
        self.refreshToken = refreshToken
    }
    
    init(object: MarshaledObject) throws {
        self.accessToken = try object <| OAuth2Token.accessTokenKey
        let expiresIn: TimeInterval = try object <| OAuth2Token.expiresInKey
        self.expiresAt = Date(timeIntervalSinceNow: expiresIn)
        self.refreshToken = try object <| OAuth2Token.refreshTokenKey
    }

    init(key: String) throws {
        let dictionary: MarshaledObject = try OAuth2Token.keychain.valueForKey(OAuth2Token.tokenKey(key))
        
        self.accessToken = try dictionary <| OAuth2Token.accessTokenKey
        self.expiresAt = try dictionary <| OAuth2Token.expiresAtKey
        self.refreshToken = try dictionary <| OAuth2Token.refreshTokenKey
    }
    
    
    // MARK: - Public functions

    func lock(_ key: String) throws {
        let tokenValues: NSDictionary = [
            OAuth2Token.accessTokenKey: accessToken as AnyObject,
            OAuth2Token.expiresAtKey: expiresAt as AnyObject,
            OAuth2Token.refreshTokenKey: refreshToken as AnyObject? ?? "" as AnyObject
        ]
        try OAuth2Token.keychain.set(tokenValues, forKey: OAuth2Token.tokenKey(key))
    }

    static func delete(_ key: String) {
        OAuth2Token.keychain.deleteValue(forKey: tokenKey(key))
    }

}


// MARK: - Private helper functions

private extension OAuth2Token {

    static func tokenKey(_ key: String) -> String {
        return "\(key).token"
    }

}
