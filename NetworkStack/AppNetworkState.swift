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
    
    // MARK: - Error
    
    enum Error: ErrorType {
        case TypeMismatch
    }
    

    // MARK: - Shared instance

    public static var currentAppState: AppNetworkState? {
        get {
            if let currentAppState = self.currentAppState {
                return currentAppState
            }
            if let dictionary = NSUserDefaults.standardUserDefaults().objectForKey(AppNetworkState.appNetworkStateKey) as? [String: AnyObject] {
                do {
                    let state = try AppNetworkState(dictionary: dictionary)
                    self.currentAppState = state
                    return state
                } catch {
                    return nil
                }
            }
            return nil
        }
        set {
            self.currentAppState = newValue
            persistState()
        }
    }


    // MARK: - Public properties

    public let apiURLString: String
    public let tokenEndpointURLString: String
    public let environmentKey: String
    public static var loggedIn: Bool {
        guard let currentAppState = currentAppState else { return false }
        return currentAppState.accessToken != nil
    }
    
    
    // MARK: - Constants

    private static let apiURLStringKey = "apiURLString"
    private static let tokenEndpointURLStringKey = "tokenEndpointURLString"
    private static let environmentKeyKey = "environmentKey"
    private static let appNetworkStateKey = "appNetworkState"
    

    // MARK: - Initializers

    public init(apiURLString: String, tokenEndpointURLString: String, environmentKey: String) {
        self.apiURLString = apiURLString
        self.tokenEndpointURLString = tokenEndpointURLString
        self.environmentKey = environmentKey
    }
    
    init(dictionary: [String: AnyObject]) throws {
        guard let apiURLString = dictionary[AppNetworkState.apiURLStringKey] as? String else { throw Error.TypeMismatch }
        guard let tokenEndpointURLString = dictionary[AppNetworkState.tokenEndpointURLStringKey] as? String else { throw Error.TypeMismatch }
        guard let environmentKey = dictionary[AppNetworkState.environmentKeyKey] as? String else { throw Error.TypeMismatch }
        
        self.apiURLString = apiURLString
        self.tokenEndpointURLString = tokenEndpointURLString
        self.environmentKey = environmentKey
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


// MARK: - Private functions

private extension AppNetworkState {

    static func persistState() {
        guard let currentAppState = currentAppState else { return }
        var dictionary = [String: AnyObject]()
        dictionary[apiURLStringKey] = currentAppState.apiURLString
        dictionary[tokenEndpointURLStringKey] = currentAppState.tokenEndpointURLString
        dictionary[environmentKeyKey] = currentAppState.environmentKey
        
        NSUserDefaults.standardUserDefaults().setObject(dictionary, forKey: appNetworkStateKey)
    }
    
}
