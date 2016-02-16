//
//  AppNetworkState.swift
//  NetworkStack
//
//  Created by Tim Shadel on 2/13/16.
//  Copyright © 2016 OC Tanner. All rights reserved.
//

import Foundation
import JaSON


public struct AppNetworkState {

    // MARK: - Shared instance

    public static var currentAppState: AppNetworkState?


    // MARK: - Public properties

    public let apiURLString: String
    public let tokenEndpointURLString: String
    public let environmentKey: String
    public let transientState: Bool


    // MARK: - Initializers

    public init(apiURLString: String, tokenEndpointURLString: String, environmentKey: String, transientState: Bool = false) {
        self.apiURLString = apiURLString
        self.tokenEndpointURLString = tokenEndpointURLString
        self.environmentKey = environmentKey
        self.transientState = transientState
    }


    // MARK: - Internal properties

    var accessToken: String? {
        do {
            let token = try OAuth2Token(key: environmentKey)
            if NSDate().compare(token.expiresAt) == .OrderedAscending {
                return token.accessToken
            }
        } catch {
            print(error)
        }
        return nil
    }
    
}


// MARK: - Internal helper functions

extension AppNetworkState {

    func urlForEndpoint(endpoint: String) -> NSURL? {
        guard let baseURL = NSURL(string: apiURLString) else { return nil }
        return NSURL(string: endpoint, relativeToURL: baseURL)
    }

    func saveToken(json: JSONObject) throws {
        let token = try OAuth2Token(json: json)
        try token.lock(environmentKey)
    }

    func deleteToken() {
        OAuth2Token.delete(environmentKey)
    }

}
