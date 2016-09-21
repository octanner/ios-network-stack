//
//  AuthRequests.swift
//  NetworkStack
//
//  Created by Ben Norris on 2/11/16.
//  Copyright © 2016 OC Tanner. All rights reserved.
//

import Foundation
import Marshal

public protocol AuthRequests {
    func authenticate(username: String, password: String, completion: @escaping Network.ResponseCompletion)
    func authenticate(pairingCode: String, completion: @escaping Network.ResponseCompletion)
    func authenticate(tokenJSON: JSONObject) throws
    func refreshToken(completion: @escaping Network.ResponseCompletion)
    func logOut()
}

public struct AuthAPIRequests: AuthRequests {
    
    // MARK: - Types
    
    public enum AuthError: Error {
        case refreshTokenMissing
    }
    

    // MARK: - Public initializer

    public init() { }

    
    // MARK: - Internal properties
    
    var network = Network()
    
    fileprivate var defaultSession: URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = ["content-type": "application/json"]
        configuration.timeoutIntervalForRequest = 10.0
        return URLSession(configuration: configuration)
    }
    
    fileprivate var activeSession: URLSession {
        return overrideSession ?? defaultSession
    }
    
    public var overrideSession: URLSession?

    
    // MARK: - Public API
    
    /// - Precondition: `AppNetworkState.currentAppState` must not be nil
    public func authenticate(username: String, password: String, completion: @escaping Network.ResponseCompletion) {
        guard let appNetworkState = AppNetworkState.currentAppState else { fatalError("Must configure current app state to log in") }
        guard let url = URL(string: appNetworkState.tokenEndpointURLString) else {
            let error = NetworkError.malformedEndpoint(endpoint: appNetworkState.tokenEndpointURLString)
            completion(.error(error))
            return
        }
        let parameters = [
            "grant_type": "password",
            "username": username,
            "password": password
        ]
        
        URLCache.shared.removeAllCachedResponses()

        let session = activeSession
        network.post(url, session: session, parameters: parameters) { result in
            switch result {
            case let .ok(json):
                do {
                    try appNetworkState.saveToken(json)
                    completion(result)
                } catch {
                    completion(.error(error))
                }
            case .error:
                completion(result)
            }
        }
    }
    
    /// - Precondition: `AppNetworkState.currentAppState` must not be nil
    public func authenticate(pairingCode: String, completion: @escaping Network.ResponseCompletion) {
        guard let appNetworkState = AppNetworkState.currentAppState else { fatalError("Must configure current app state to log in") }
        guard let url = URL(string: appNetworkState.tokenEndpointURLString) else {
            let error = NetworkError.malformedEndpoint(endpoint: appNetworkState.tokenEndpointURLString)
            completion(.error(error))
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
        network.post(url, session: session, parameters: parameters) { result in
            switch result {
            case let .ok(json):
                do {
                    try appNetworkState.saveToken(json)
                    try appNetworkState.saveClient(json)
                    completion(result)
                } catch {
                    completion(.error(error))
                }
            case .error:
                completion(result)
            }
        }
    }
    
    public func refreshToken(completion: @escaping Network.ResponseCompletion) {
        guard let appNetworkState = AppNetworkState.currentAppState else { fatalError("Must configure current app state to log in") }
        guard let refreshToken = appNetworkState.refreshToken else { return completion(.error(AuthError.refreshTokenMissing)) }
        guard let url = URL(string: appNetworkState.tokenEndpointURLString) else {
            let error = NetworkError.malformedEndpoint(endpoint: appNetworkState.tokenEndpointURLString)
            completion(.error(error))
            return
        }
        var parameters = [
            "grant_type": "refresh_token",
            "refresh_token" : refreshToken
        ]
        if let client = appNetworkState.client {
            parameters["client_id"] = client.id
            parameters["client_secret"] = client.secret
        }
        
        URLCache.shared.removeAllCachedResponses()
        
        let session = activeSession
        network.post(url, session: session, parameters: parameters) { result in
            switch result {
            case let .ok(json):
                do {
                    try appNetworkState.saveToken(json)
                    completion(result)
                } catch {
                    completion(.error(error))
                }
            case .error:
                completion(result)
            }
        }
    }
    
    /// - Precondition: `AppNetworkState.currentAppState` must not be nil
    public func authenticate(tokenJSON: JSONObject) throws {
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
