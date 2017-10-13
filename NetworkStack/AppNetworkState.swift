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
    
    enum AppNetworkStateError: Error {
        case typeMismatch
    }
    

    // MARK: - Shared instances

    public static var currentAppState: AppNetworkState? {
        get {
            if let currentState = savedCurrentAppState {
                return currentState
            }
            if let dictionary = UserDefaults.standard.object(forKey: AppNetworkState.appNetworkStateKey) as? [String: AnyObject] {
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

    private static var savedCurrentAppState: AppNetworkState?
    

    // MARK: - Public properties

    public let apiURLString: String
    public let secondaryApiUrlString: String
    public let tokenEndpointURLString: String
    public let environmentKey: String
    public static var loggedIn: Bool {
        guard let currentAppState = currentAppState else { return false }
        return currentAppState.accessToken != nil
    }
    public var accessToken: String? {
        do {
            let token = try OAuth2Token(key: environmentKey)
            if Date().compare(token.expiresAt) == .orderedAscending {
                return token.accessToken
            }
        } catch {
            print(error)
        }
        return nil
    }
    public var refreshToken: String? {
        do {
            let token = try OAuth2Token(key: environmentKey)
            return token.refreshToken
        } catch {
            print(error)
        }
        return nil
    }
    public var client: (id: String, secret: String)? {
        do {
            let client = try OAuth2Client(key: environmentKey)
            return (id: client.id, secret: client.secret)
        } catch {
            print(error)
        }
        return nil
    }
    
    
    // MARK: - Constants

    private static let apiURLStringKey = "NetworkStack.apiURLString"
    private static let secondaryApiUrlString = "NetworkStack.secondaryApiURLString"
    private static let tokenEndpointURLStringKey = "NetworkStack.tokenEndpointURLString"
    private static let environmentKeyKey = "NetworkStack.environmentKey"
    private static let appNetworkStateKey = "NetworkStack.appNetworkState"
    

    // MARK: - Initializers

    public init(apiURLString: String, secondaryApiUrlString: String, tokenEndpointURLString: String, environmentKey: String) {
        self.apiURLString = apiURLString
        self.secondaryApiUrlString = secondaryApiUrlString
        self.tokenEndpointURLString = tokenEndpointURLString
        self.environmentKey = environmentKey
    }
    
    init(dictionary: [String: AnyObject]) throws {
        guard let apiURLString = dictionary[AppNetworkState.apiURLStringKey] as? String else { throw AppNetworkStateError.typeMismatch }
        guard let secondaryApiUrlString = dictionary[AppNetworkState.secondaryApiUrlString] as? String else { throw AppNetworkStateError.typeMismatch }
        guard let tokenEndpointURLString = dictionary[AppNetworkState.tokenEndpointURLStringKey] as? String else { throw AppNetworkStateError.typeMismatch }
        guard let environmentKey = dictionary[AppNetworkState.environmentKeyKey] as? String else { throw AppNetworkStateError.typeMismatch }
        
        self.apiURLString = apiURLString
        self.secondaryApiUrlString = secondaryApiUrlString
        self.tokenEndpointURLString = tokenEndpointURLString
        self.environmentKey = environmentKey
    }
    
    
    // MARK: - Internal helper functions

    func urlForEndpoint(_ endpoint: String) -> URL? {
        if let baseURL = URL(string: secondaryApiUrlString), endpoint.contains("victories/recognitions") {
            return URL(string: endpoint, relativeTo: baseURL)
        } else if let baseURL = URL(string: apiURLString) {
            return URL(string: endpoint, relativeTo: baseURL)
        } else {
                return nil
        }
    }

    func saveToken(_ json: JSONObject) throws {
        let token = try OAuth2Token(object: json)
        try token.lock(environmentKey)
    }

    func saveClient(_ json: JSONObject) throws {
        let client = try OAuth2Client(object: json)
        try client.lock(with: environmentKey)
    }
    
    func deleteToken() {
        OAuth2Token.delete(environmentKey)
    }
    
    func deleteClient() {
        OAuth2Client.delete(with: environmentKey)
    }


    // MARK: - Private functions

    private static func persistState() {
        guard let currentState = savedCurrentAppState else { return }
        var dictionary = [String: AnyObject]()
        dictionary[apiURLStringKey] = currentState.apiURLString as AnyObject?
        dictionary[secondaryApiUrlString] = currentState.secondaryApiUrlString as AnyObject?
        dictionary[tokenEndpointURLStringKey] = currentState.tokenEndpointURLString as AnyObject?
        dictionary[environmentKeyKey] = currentState.environmentKey as AnyObject?
        
        UserDefaults.standard.set(dictionary, forKey: appNetworkStateKey)
    }
    
}
