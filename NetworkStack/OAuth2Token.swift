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

    let accessToken: String
    let expiresAt: Date
    let refreshToken: String?
    
    private static let accessTokenKey = "access_token"
    private static let expiresAtKey = "expires_at"
    private static let expiresInKey = "expires_in"
    private static let expiresKey = "expires"
    private static let refreshTokenKey = "refresh_token"
    
    init(accessToken: String, expiresAt: Date = Date.distantPast, refreshToken: String? = nil) {
        self.accessToken = accessToken
        self.expiresAt = expiresAt
        self.refreshToken = refreshToken
    }
    
    init(object: MarshaledObject) throws {
        self.accessToken = try object <| OAuth2Token.accessTokenKey
        var expiresIn: TimeInterval? = try object.value(for: OAuth2Token.expiresInKey) // common auth
        // Common Auth uses `expires_in` and core Auth uses `expires`
        // check for an optioal `expires_in` first, and if it doesn't exist then require `expires`.
        if expiresIn == nil {
            let expires: TimeInterval = try object <| OAuth2Token.expiresKey // core auth
            expiresIn = expires
        }
        self.expiresAt = Date(timeIntervalSinceNow: expiresIn!)
        self.refreshToken = try object <| OAuth2Token.refreshTokenKey
    }

    init?(key: String, keychain: Keychain) throws {
        guard let dictionary: MarshaledObject = try keychain.optionalForKey(OAuth2Token.tokenKey(key)) else { return nil }
        
        self.accessToken = try dictionary <| OAuth2Token.accessTokenKey
        self.expiresAt = try dictionary <| OAuth2Token.expiresAtKey
        self.refreshToken = try dictionary <| OAuth2Token.refreshTokenKey
    }
    
    func lock(_ key: String, keychain: Keychain) throws {
        let tokenValues: NSDictionary = [
            OAuth2Token.accessTokenKey: accessToken as AnyObject,
            OAuth2Token.expiresAtKey: expiresAt as AnyObject,
            OAuth2Token.refreshTokenKey: refreshToken as AnyObject? ?? "" as AnyObject
        ]
        try keychain.set(tokenValues, forKey: OAuth2Token.tokenKey(key))
    }

    static func delete(_ key: String, keychain: Keychain) {
        keychain.deleteValue(forKey: tokenKey(key))
    }

    static func expireAccessToken(with key: String, keychain: Keychain) {
        do {
            guard let dictionary: MarshaledObject = try keychain.valueForKey(OAuth2Token.tokenKey(key)) else { return }
            let accessToken: String = try dictionary.value(for: OAuth2Token.accessTokenKey)
            let refreshToken: String? = try dictionary.value(for: OAuth2Token.refreshTokenKey)
            let expiredOAuth2Token = OAuth2Token(accessToken: accessToken, expiresAt: Date.distantPast, refreshToken: refreshToken)
            try expiredOAuth2Token.lock(key, keychain: keychain)
        } catch {
            // If we can't access the token structure, don't propagate the error
        }
    }
    
    private static func tokenKey(_ key: String) -> String {
        return "\(key).token"
    }

}
