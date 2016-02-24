//
//  AppNetworkState.swift
//  NetworkStack
//
//  Created by Tim Shadel on 2/13/16.
//  Copyright © 2016 OC Tanner. All rights reserved.
//

import Foundation
import Marshal


public struct AppNetworkState {
    
    // MARK: - Error
    
    enum Error: ErrorType {
        case TypeMismatch
    }
    

    // MARK: - Shared instance

    public static var currentAppState: AppNetworkState? {
        get {
            if let currentState = savedCurrentAppState {
                return currentState
            }
            if let dictionary = NSUserDefaults.standardUserDefaults().objectForKey(AppNetworkState.appNetworkStateKey) as? [String: AnyObject] {
                do {
                    let state = try AppNetworkState(dictionary: dictionary)
                    savedCurrentAppState = state
                    return state
                } catch {
                    return nil
                }
            }
            return nil
        }
        set {
            savedCurrentAppState = newValue
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
    
    
    // MARK: - Private shared instance
    
    private static var savedCurrentAppState: AppNetworkState?
    
    
    // MARK: - Constants

    private static let apiURLStringKey = "NetworkStack.apiURLString"
    private static let tokenEndpointURLStringKey = "NetworkStack.tokenEndpointURLString"
    private static let environmentKeyKey = "NetworkStack.environmentKey"
    private static let appNetworkStateKey = "NetworkStack.appNetworkState"
    

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
        let token = try OAuth2Token(object: json)
        try token.lock(environmentKey)
    }

    func saveClient(json: JSONObject) throws {
        let client = try OAuth2Client(object: json)
        try client.lock(environmentKey)
    }
    
    func deleteToken() {
        OAuth2Token.delete(environmentKey)
    }
    
    func deleteClient() {
        OAuth2Client.delete(environmentKey)
    }

}


// MARK: - Private functions

private extension AppNetworkState {

    static func persistState() {
        guard let currentState = savedCurrentAppState else { return }
        var dictionary = [String: AnyObject]()
        dictionary[apiURLStringKey] = currentState.apiURLString
        dictionary[tokenEndpointURLStringKey] = currentState.tokenEndpointURLString
        dictionary[environmentKeyKey] = currentState.environmentKey
        
        NSUserDefaults.standardUserDefaults().setObject(dictionary, forKey: appNetworkStateKey)
    }
    
}
