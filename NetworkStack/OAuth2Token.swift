//
//  OAuth2Token.swift
//  NetworkStack
//
//  Created by Ben Norris on 2/11/16.
//  Copyright © 2016 OC Tanner. All rights reserved.
//

import Foundation
import JaSON
import SimpleKeychain

struct OAuth2Token: JSONObjectConvertible {

    // MARK: - Error

    enum Error: ErrorType {
        case TypeMismatch
    }


    // MARK: - Public properties
    
    let accessToken: String
    let expiresAt: NSDate
    let refreshToken: String?
    
    
    // MARK: - Private properties

    private static let keychain = Keychain()
    
    
    // MARK: - Constants
    
    private let accessTokenKey = "access_token"
    private let expiresAtKey = "expires_at"
    private let expiresInKey = "expires_in"
    private let refreshTokenKey = "refresh_token"
    
    
    // MARK: - Initializers
    
    init(accessToken: String, expiresAt: NSDate? = nil, refreshToken: String? = nil) {
        self.accessToken = accessToken
        self.expiresAt = expiresAt ?? NSDate.distantFuture()
        self.refreshToken = refreshToken
    }
    
    init(json: JSONObject) throws {
        self.accessToken = try json <| accessTokenKey
        let expiresIn: NSTimeInterval = try json <| expiresInKey
        self.expiresAt = NSDate(timeIntervalSinceNow: expiresIn)
        self.refreshToken = try json <| refreshTokenKey
    }

    init(key: String) throws {
        let dictionary: [String: AnyObject] = try OAuth2Token.keychain.valueForKey(OAuth2Token.tokenKey(key))

        guard let accessToken = dictionary[accessTokenKey] as? String else { throw Error.TypeMismatch }
        guard let expiresAt = dictionary[expiresAtKey] as? NSDate else { throw Error.TypeMismatch }
        guard let refresh = dictionary[refreshTokenKey] as? String else { throw Error.TypeMismatch }

        self.accessToken = accessToken
        self.expiresAt = expiresAt
        self.refreshToken = refresh == "" ? nil : refresh
    }
    
    
    // MARK: - Public functions

    func lock(key: String) throws {
        let tokenValues: [String: AnyObject] = [
            accessTokenKey: accessToken,
            expiresAtKey: expiresAt,
            refreshTokenKey: refreshToken ?? ""
        ]
        try OAuth2Token.keychain.set(tokenValues, forKey: OAuth2Token.tokenKey(key))
    }

    static func delete(key: String) {
        OAuth2Token.keychain.deleteValue(forKey: tokenKey(key))
    }


    // MARK: - Private helper functions

    private static func tokenKey(key: String) -> String {
        return "\(key).token"
    }

}
