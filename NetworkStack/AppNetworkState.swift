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


    // MARK: - Internal helper functions

    var authToken: OAuth2Token? {
        return try? OAuth2Token(key: environmentKey)
    }

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
