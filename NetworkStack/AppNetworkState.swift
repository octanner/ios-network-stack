//
//  AppNetworkState.swift
//  NetworkStack
//
//  Created by Tim Shadel on 2/13/16.
//  Copyright © 2016 OC Tanner. All rights reserved.
//

import Foundation
import Marshal
import SimpleKeychain


public struct AppNetworkState {
    
    // MARK: - Error
    
    enum AppNetworkStateError: Error {
        case typeMismatch
    }
    

    // MARK: - Shared instances

    public static var currentAppState: AppNetworkState? {
        didSet {
            persistState()
        }
    }

    public static func loadAppState(from appGroup: String?) -> AppNetworkState? {
        let defaults = UserDefaults(suiteName: appGroup) ?? UserDefaults.standard
        if let dictionary = defaults.object(forKey: AppNetworkState.appNetworkStateKey) as? [String: Any] {
            do {
                let keychain = Keychain(group: appGroup)
                let state = try AppNetworkState(dictionary: dictionary, keychain: keychain)
                currentAppState = state
                return state
            } catch {
                return nil
            }
        }
        return nil
    }


    // MARK: - Public properties

    public let apiURLString: String
    public let tokenEndpointURLString: String
    public let environmentKey: String
    public let appSlug: String
    public let keychain: Keychain
    public static var loggedIn: Bool {
        guard let currentAppState = currentAppState else { return false }
        return currentAppState.accessToken != nil
    }
    public static var defaultAppVersionSlug: String {
        return Bundle.main.identifierBuildVersion
    }
    public var appVersionSlug: String {
        return "\(appSlug)-\(Bundle.main.buildVersion)"
    }
    public var accessToken: String? {
        do {
            let token = try OAuth2Token(key: environmentKey, keychain: keychain)
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
            let token = try OAuth2Token(key: environmentKey, keychain: keychain)
            return token.refreshToken
        } catch {
            print(error)
        }
        return nil
    }
    public var client: (id: String, secret: String)? {
        do {
            let client = try OAuth2Client(key: environmentKey, keychain: keychain)
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
    private static let keychainGroupKey = "NetworkStack.keychainGroupKey"
    private static let appNetworkStateKey = "NetworkStack.appNetworkState"
    

    // MARK: - Initializers

    public init(apiURLString: String, tokenEndpointURLString: String, environmentKey: String, keychain: Keychain, appSlug: String? = nil) {
        self.apiURLString = apiURLString
        self.tokenEndpointURLString = tokenEndpointURLString
        self.environmentKey = environmentKey
        self.appSlug = appSlug ?? Bundle.main.identifier
        self.keychain = keychain
    }
    
    private init(dictionary: [String: Any], keychain: Keychain) throws {
        guard let apiURLString = dictionary[AppNetworkState.apiURLStringKey] as? String else { throw AppNetworkStateError.typeMismatch }
        guard let tokenEndpointURLString = dictionary[AppNetworkState.tokenEndpointURLStringKey] as? String else { throw AppNetworkStateError.typeMismatch }
        guard let environmentKey = dictionary[AppNetworkState.environmentKeyKey] as? String else { throw AppNetworkStateError.typeMismatch }
		let appSlug = dictionary[AppNetworkState.appSlugKey] as? String ?? Bundle.main.identifier
        
        self.apiURLString = apiURLString
        self.tokenEndpointURLString = tokenEndpointURLString
        self.environmentKey = environmentKey
        self.appSlug = appSlug
        self.keychain = keychain
    }
    
    
    // MARK: - Internal helper functions

    func urlForEndpoint(_ endpoint: String) -> URL? {
        guard let baseURL = URL(string: apiURLString) else { return nil }
        return URL(string: endpoint, relativeTo: baseURL)
    }

    func saveToken(_ json: JSONObject) throws {
        let token = try OAuth2Token(object: json)
        try token.lock(environmentKey, keychain: keychain)
    }

    func saveClient(_ json: JSONObject) throws {
        let client = try OAuth2Client(object: json)
        try client.lock(with: environmentKey, keychain: keychain)
    }
    
    func deleteToken() {
        OAuth2Token.delete(environmentKey, keychain: keychain)
    }
    
    func deleteClient() {
        OAuth2Client.delete(with: environmentKey, keychain: keychain)
    }


    // MARK: - Private functions

    private static func persistState() {
        guard let currentState = currentAppState else { return }
        var dictionary = [String: Any]()
        dictionary[apiURLStringKey] = currentState.apiURLString
        dictionary[tokenEndpointURLStringKey] = currentState.tokenEndpointURLString
        dictionary[environmentKeyKey] = currentState.environmentKey

        let defaults = UserDefaults(suiteName: currentState.keychain.group) ?? UserDefaults.standard
        defaults.set(dictionary, forKey: appNetworkStateKey)
    }
    
}
