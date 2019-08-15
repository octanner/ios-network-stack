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
    public let secondaryApiUrlString: String
    public let tokenEndpointURLString: String
    public let environmentKey: String
    public let appSlug: String
    public let keychain: Keychain
    public static func loggedIn() throws -> Bool {
        guard let currentAppState = currentAppState else { return false }
        return try currentAppState.accessToken() != nil
    }
    public static var defaultAppVersionSlug: String {
        return "vision-ios"
    }
    public var appVersionSlug: String {
        return "\(appSlug)-\(Bundle.main.buildVersion)"
    }
    public func accessToken() throws -> String? {
        guard let token = try OAuth2Token(key: environmentKey, keychain: keychain) else { return nil }
        if Date().compare(token.expiresAt) == .orderedAscending {
            return token.accessToken
        } else {
            return nil
        }
    }
    public func isJWT() throws -> Bool {
        guard let token = try OAuth2Token(key: environmentKey, keychain: keychain) else { return false }
        return token.accessToken.contains(".")
    }
    /// Loads the OAuth2Token from keychain, if present.
    public func loadRefreshToken() throws -> String? {
        guard let token = try OAuth2Token(key: environmentKey, keychain: keychain) else { return nil }
        return token.refreshToken
    }
    public func client() throws -> (id: String, secret: String)? {
        guard let client = try OAuth2Client(key: environmentKey, keychain: keychain) else { return nil }
        return (id: client.id, secret: client.secret)
    }


    // MARK: - Constants

    private static let apiURLStringKey = "NetworkStack.apiURLString"
    private static let secondaryApiUrlStringKey = "NetworkStack.secondaryApiURLString"
    private static let tokenEndpointURLStringKey = "NetworkStack.tokenEndpointURLString"
    private static let environmentKeyKey = "NetworkStack.environmentKey"
    private static let languageKey = "NetworkStack.languageKey"
    private static let appSlugKey = "NetworkStack.appSlugKey"
    private static let keychainGroupKey = "NetworkStack.keychainGroupKey"
    private static let appNetworkStateKey = "NetworkStack.appNetworkState"


    // MARK: - Initializers

    public init(apiURLString: String, secondaryApiUrlString: String, tokenEndpointURLString: String, environmentKey: String, keychain: Keychain, appSlug: String? = nil) {
        self.apiURLString = apiURLString
        self.secondaryApiUrlString = secondaryApiUrlString
        self.tokenEndpointURLString = tokenEndpointURLString
        self.environmentKey = environmentKey
        self.appSlug = appSlug ?? "vision-ios"
        self.keychain = keychain
    }

    private init(dictionary: [String: Any], keychain: Keychain) throws {
        guard let apiURLString = dictionary[AppNetworkState.apiURLStringKey] as? String else { throw AppNetworkStateError.typeMismatch }
        guard let tokenEndpointURLString = dictionary[AppNetworkState.tokenEndpointURLStringKey] as? String else { throw AppNetworkStateError.typeMismatch }
        guard let environmentKey = dictionary[AppNetworkState.environmentKeyKey] as? String else { throw AppNetworkStateError.typeMismatch }
        guard let secondaryApiUrlString = dictionary[AppNetworkState.secondaryApiUrlStringKey] as? String else { throw AppNetworkStateError.typeMismatch }
		let appSlug = dictionary[AppNetworkState.appSlugKey] as? String ?? "vision-ios"

        self.apiURLString = apiURLString
        self.tokenEndpointURLString = tokenEndpointURLString
        self.environmentKey = environmentKey
        self.appSlug = appSlug
        self.keychain = keychain
        self.secondaryApiUrlString = secondaryApiUrlString
    }


    // MARK: - Internal helper functions

    func urlForEndpoint(_ endpoint: String) -> URL? {
        if let baseURL = URL(string: secondaryApiUrlString), endpoint.starts(with: "/victories") {
            return URL(string: endpoint, relativeTo: baseURL)
        } else if let baseURL = URL(string: apiURLString) {
            return URL(string: endpoint, relativeTo: baseURL)
        } else {
                return nil
        }
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

    func expireAccessToken() {
        OAuth2Token.expireAccessToken(with: environmentKey, keychain: keychain)
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
        dictionary[secondaryApiUrlStringKey] = currentState.secondaryApiUrlString
        dictionary[appSlugKey] = currentState.appSlug

        let defaults = UserDefaults(suiteName: currentState.keychain.group) ?? UserDefaults.standard
        defaults.set(dictionary, forKey: appNetworkStateKey)
    }

}
