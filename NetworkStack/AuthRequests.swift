//
//  AuthRequests.swift
//  NetworkStack
//
//  Created by Ben Norris on 2/11/16.
//  Copyright © 2016 OC Tanner. All rights reserved.
//

import Foundation
import Marshal
import SwiftyBeaver

public struct Credentials {
    public var username: String
    public var password: String
    
    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}

public protocol AuthRequests {
    func authenticate(with credentials: Credentials, completion: @escaping Network.ResponseCompletion)
    func authenticate(with pairingCode: String, completion: @escaping Network.ResponseCompletion)
    func authenticate(with tokenJSON: JSONObject) throws
    func refreshToken(completion: @escaping Network.ResponseCompletion)
    func logOut()
}

public struct AuthAPIRequests: AuthRequests {
    
    // MARK: - Types
    
    public enum AuthError: Error {
        case refreshTokenMissing
        case clientCredentialsMissing
    }
    

    // MARK: - Public initializer

    public init() { }

    
    // MARK: - Internal properties
    
    var network = Network()
    
    private var defaultSession: URLSession {
        var appVersionSlug = AppNetworkState.defaultAppVersionSlug
        if let appNetworkState = AppNetworkState.currentAppState {
            appVersionSlug = appNetworkState.appVersionSlug
        }
        let configuration = URLSessionConfiguration.ephemeral

        let headers: [String:String] = [
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Accept-Language": Bundle.main.acceptLanguages,
            "X-Client-Id": appVersionSlug
        ]
		configuration.httpAdditionalHeaders = headers

        configuration.timeoutIntervalForRequest = 10.0
        return URLSession(configuration: configuration)
    }
    
    fileprivate var activeSession: URLSession {
        return overrideSession ?? defaultSession
    }
    
    public var overrideSession: URLSession?

    
    // MARK: - Public API
    
    /// - Precondition: `AppNetworkState.currentAppState` must not be nil
    public func authenticate(with credentials: Credentials, completion: @escaping Network.ResponseCompletion) {
        guard let appNetworkState = AppNetworkState.currentAppState else { fatalError("Must configure current app state to log in") }
        guard let url = URL(string: appNetworkState.tokenEndpointURLString) else {
            let error = NetworkError.malformedEndpoint(endpoint: appNetworkState.tokenEndpointURLString)
            completion(.error(error), nil)
            return
        }
        let parameters = [
            "grant_type": "password",
            "username": credentials.username,
            "password": credentials.password
        ]
        
        URLCache.shared.removeAllCachedResponses()

        let session = activeSession
        network.post(to: url, using: session, with: parameters) { result, headers in
            switch result {
            case let .ok(json):
                do {
                    try appNetworkState.saveToken(json)
                    completion(result, headers)
                } catch {
                    completion(.error(error), headers)
                }
            case .error:
                completion(result, headers)
            }
        }
    }
    
    /// - Precondition: `AppNetworkState.currentAppState` must not be nil
    public func authenticate(with pairingCode: String, completion: @escaping Network.ResponseCompletion) {
        guard let appNetworkState = AppNetworkState.currentAppState else { fatalError("Must configure current app state to log in") }
        guard let url = URL(string: appNetworkState.tokenEndpointURLString) else {
            let error = NetworkError.malformedEndpoint(endpoint: appNetworkState.tokenEndpointURLString)
            completion(.error(error), nil)
            return
        }
        let parameters = [
            "client_id": pairingCode,
            "grant_type": "device",
            "device_id" : UIDevice.currentIdentifier,
            "device_name" : UIDevice.current.name
        ]
        
        URLCache.shared.removeAllCachedResponses()
        
        let session = activeSession
        network.post(to: url, using: session, with: parameters) { result, headers in
            switch result {
            case let .ok(json):
                do {
                    try appNetworkState.saveToken(json)
                    try appNetworkState.saveClient(json)
                    completion(result, headers)
                } catch {
                    completion(.error(error), headers)
                }
            case .error:
                completion(result, headers)
            }
        }
    }
    
    public func refreshToken(completion: @escaping Network.ResponseCompletion) {
        guard let appNetworkState = AppNetworkState.currentAppState else { fatalError("Must configure current app state to log in") }
        var token: String?
        var clientCreds: (id: String, secret: String)?
        do {
            token = try appNetworkState.refreshToken()
            clientCreds = try appNetworkState.client()
        } catch {
            completion(.error(error), nil)
            return
        }
        guard let refreshToken = token else { return completion(.error(AuthError.refreshTokenMissing), nil) }
        guard let client = clientCreds else { return completion(.error(AuthError.clientCredentialsMissing), nil) }
        guard let url = URL(string: appNetworkState.tokenEndpointURLString) else {
            let error = NetworkError.malformedEndpoint(endpoint: appNetworkState.tokenEndpointURLString)
            completion(.error(error), nil)
            return
        }
        var parameters: [String:Any] = [
            "grant_type": "refresh_token",
            "refresh_token" : refreshToken
        ]
        parameters["client_id"] = client.id
        parameters["client_secret"] = client.secret
        
        URLCache.shared.removeAllCachedResponses()

        SwiftyBeaver.info("at=refresh-token token-last6=\(refreshToken.last(count: 6))")
        let session = activeSession
        network.post(to: url, using: session, with: parameters) { result, headers in
            switch result {
            case let .ok(json):
                do {
                    try appNetworkState.saveToken(json)
                    completion(result, headers)
                } catch {
                    completion(.error(error), headers)
                }
            case .error:
                completion(result, headers)
            }
        }
    }
    
    /// - Precondition: `AppNetworkState.currentAppState` must not be nil
    public func authenticate(with tokenJSON: JSONObject) throws {
        guard let appNetworkState = AppNetworkState.currentAppState else { fatalError("Must configure current app state to log in") }
        try appNetworkState.saveToken(tokenJSON)
    }
    
    public func logOut() {
        guard let appNetworkState = AppNetworkState.currentAppState else { return }
        URLCache.shared.removeAllCachedResponses()
        appNetworkState.deleteToken()
        appNetworkState.deleteClient()
    }

}


extension UIDevice {

    static var isSimulator: Bool {
        return ProcessInfo.processInfo.environment.keys.contains("SIMULATOR_DEVICE_NAME")
    }

    static var currentIdentifier: String {
        if isSimulator {
            return "5F21210D-3600-418E-BF37-ABA206DD0AFF"
        } else {
            return UIDevice.current.identifierForVendor!.uuidString
        }
    }

}


extension String {

    func last(count: Int) -> String {
        let from = index(endIndex, offsetBy: -count, limitedBy: startIndex) ?? startIndex
        let str = String(self[from...])
        return str
    }

}
