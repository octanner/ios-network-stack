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

struct OAuth2Token: Marshal.ObjectConvertible {

    // MARK: - Error

    enum Error: ErrorType {
        case TypeMismatch
    }


    // MARK: - Internal properties
    
    let accessToken: String
    let expiresAt: NSDate
    let refreshToken: String?
    
    
    // MARK: - Private properties

    private static let keychain = Keychain()
    
    
    // MARK: - Constants
    
    private static let accessTokenKey = "access_token"
    private static let expiresAtKey = "expires_at"
    private static let expiresInKey = "expires_in"
    private static let refreshTokenKey = "refresh_token"
    
    
    // MARK: - Initializers
    
    init(accessToken: String, expiresAt: NSDate = NSDate.distantFuture(), refreshToken: String? = nil) {
        self.accessToken = accessToken
        self.expiresAt = expiresAt
        self.refreshToken = refreshToken
    }
    
    init(object: JSONObject) throws {
        self.accessToken = try object <| OAuth2Token.accessTokenKey
        let expiresIn: NSTimeInterval = try object <| OAuth2Token.expiresInKey
        self.expiresAt = NSDate(timeIntervalSinceNow: expiresIn)
        self.refreshToken = try object <| OAuth2Token.refreshTokenKey
    }

    init(key: String) throws {
        let dictionary: Object = try OAuth2Token.keychain.valueForKey(OAuth2Token.tokenKey(key))
        try self.init(object: dictionary)
    }
    
    
    // MARK: - Public functions

    func lock(key: String) throws {
        let tokenValues: [String: AnyObject] = [
            OAuth2Token.accessTokenKey: accessToken,
            OAuth2Token.expiresAtKey: expiresAt,
            OAuth2Token.refreshTokenKey: refreshToken ?? ""
        ]
        try OAuth2Token.keychain.set(tokenValues, forKey: OAuth2Token.tokenKey(key))
    }

    static func delete(key: String) {
        OAuth2Token.keychain.deleteValue(forKey: tokenKey(key))
    }

}


// MARK: - Private helper functions

private extension OAuth2Token {

    static func tokenKey(key: String) -> String {
        return "\(key).token"
    }

}
