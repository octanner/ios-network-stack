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
    public let tokenEndpointURLString: String
    public let environmentKey: String
    public let appSlug: String
    public static var loggedIn: Bool {
        guard let currentAppState = currentAppState else { return false }
        return currentAppState.accessToken != nil
    }
    public static var defaultAppVersionSlug: String {
        return NSBundle.mainBundle().identifierBuildVersion
    }
    public var appVersionSlug: String {
        return "\(appSlug)-\(NSBundle.mainBundle().buildVersion)"
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
    private static let tokenEndpointURLStringKey = "NetworkStack.tokenEndpointURLString"
    private static let environmentKeyKey = "NetworkStack.environmentKey"
    private static let languageKey = "NetworkStack.languageKey"
    private static let appSlugKey = "NetworkStack.appSlugKey"
    private static let appNetworkStateKey = "NetworkStack.appNetworkState"
    

    // MARK: - Initializers

    public init(apiURLString: String, tokenEndpointURLString: String, environmentKey: String, appSlug: String? = nil) {
        self.apiURLString = apiURLString
        self.tokenEndpointURLString = tokenEndpointURLString
        self.environmentKey = environmentKey
        self.appSlug = appSlug ?? NSBundle.mainBundle().identifier
    }
    
    init(dictionary: [String: AnyObject]) throws {
        guard let apiURLString = dictionary[AppNetworkState.apiURLStringKey] as? String else { throw AppNetworkStateError.typeMismatch }
        guard let tokenEndpointURLString = dictionary[AppNetworkState.tokenEndpointURLStringKey] as? String else { throw AppNetworkStateError.typeMismatch }
        guard let environmentKey = dictionary[AppNetworkState.environmentKeyKey] as? String else { throw AppNetworkStateError.typeMismatch }
		let appSlug = dictionary[AppNetworkState.appSlugKey] as? String ?? NSBundle.mainBundle().identifier
        
        self.apiURLString = apiURLString
        self.tokenEndpointURLString = tokenEndpointURLString
        self.environmentKey = environmentKey
        self.appSlug = appSlug
    }
    
    
    // MARK: - Internal helper functions

    func urlForEndpoint(_ endpoint: String) -> URL? {
        guard let baseURL = URL(string: apiURLString) else { return nil }
        return URL(string: endpoint, relativeTo: baseURL)
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
        dictionary[tokenEndpointURLStringKey] = currentState.tokenEndpointURLString as AnyObject?
        dictionary[environmentKeyKey] = currentState.environmentKey as AnyObject?
        
        UserDefaults.standard.set(dictionary, forKey: appNetworkStateKey)
    }
    
}
