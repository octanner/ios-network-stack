//
//  AuthRequests.swift
//  NetworkStack
//
//  Created by Ben Norris on 2/11/16.
//  Copyright © 2016 OC Tanner. All rights reserved.
//

import Foundation
import DVR
import Marshal

public protocol AuthRequests {
    func authenticate(username: String, password: String, completion: Network.ResponseCompletion)
    func authenticate(pairingCode: String, completion: Network.ResponseCompletion)
    func authenticate(tokenJSON: JSONObject) throws
    func refreshToken(completion: Network.ResponseCompletion)
    func logOut()
}

public struct AuthAPIRequests: AuthRequests {
    
    // MARK: - Types
    
    public enum Error: ErrorType {
        case RefreshTokenMissing
    }
    

    // MARK: - Public initializer

    public init() { }

    
    // MARK: - Internal properties
    
    var network = Network()
    
    private var defaultSession: NSURLSession {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = ["content-type": "application/json"]
        configuration.timeoutIntervalForRequest = 10.0
        return NSURLSession(configuration: configuration)
    }
    
    var activeSession: NSURLSession {
        return staticNetwork ? staticSession : defaultSession
    }
    
    private var staticSession: NSURLSession {
        let url = NSURL(string: NSProcessInfo.processInfo().environment["cassette"]!)!
        return Session(cassetteURL: url)
    }
    
    private var staticNetwork: Bool {
        return NSProcessInfo.processInfo().environment["cassette"] != nil
    }
    
    
    // MARK: - Public API
    
    /// - Precondition: `AppNetworkState.currentAppState` must not be nil
    public func authenticate(username: String, password: String, completion: Network.ResponseCompletion) {
        guard let appNetworkState = AppNetworkState.currentAppState else { fatalError("Must configure current app state to log in") }
        guard let url = NSURL(string: appNetworkState.tokenEndpointURLString) else {
            let error = Network.Error.MalformedEndpoint(endpoint: appNetworkState.tokenEndpointURLString)
            completion(.Error(error))
            return
        }
        let parameters = [
            "grant_type": "password",
            "username": username,
            "password": password
        ]
        
        NSURLCache.sharedURLCache().removeAllCachedResponses()

        let session = activeSession
        network.post(url, session: session, parameters: parameters) { result in
            switch result {
            case let .Ok(json):
                do {
                    try appNetworkState.saveToken(json)
                    completion(result)
                } catch {
                    completion(.Error(error))
                }
            case .Error:
                completion(result)
            }
        }
    }
    
    /// - Precondition: `AppNetworkState.currentAppState` must not be nil
    public func authenticate(pairingCode: String, completion: Network.ResponseCompletion) {
        guard let appNetworkState = AppNetworkState.currentAppState else { fatalError("Must configure current app state to log in") }
        guard let url = NSURL(string: appNetworkState.tokenEndpointURLString) else {
            let error = Network.Error.MalformedEndpoint(endpoint: appNetworkState.tokenEndpointURLString)
            completion(.Error(error))
            return
        }
        let parameters = [
            "client_id": pairingCode,
            "grant_type": "device",
            "device_id" : UIDevice.currentIdentifier,
            "device_name" : UIDevice.currentDevice().name
        ]
        
        NSURLCache.sharedURLCache().removeAllCachedResponses()
        
        let session = activeSession
        network.post(url, session: session, parameters: parameters) { result in
            switch result {
            case let .Ok(json):
                do {
                    try appNetworkState.saveToken(json)
                    try appNetworkState.saveClient(json)
                    completion(result)
                } catch {
                    completion(.Error(error))
                }
            case .Error:
                completion(result)
            }
        }
    }
    
    public func refreshToken(completion: Network.ResponseCompletion) {
        guard let appNetworkState = AppNetworkState.currentAppState else { fatalError("Must configure current app state to log in") }
        guard let refreshToken = appNetworkState.refreshToken else { return completion(.Error(Error.RefreshTokenMissing)) }
        guard let url = NSURL(string: appNetworkState.tokenEndpointURLString) else {
            let error = Network.Error.MalformedEndpoint(endpoint: appNetworkState.tokenEndpointURLString)
            completion(.Error(error))
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
        
        NSURLCache.sharedURLCache().removeAllCachedResponses()
        
        let session = activeSession
        network.post(url, session: session, parameters: parameters) { result in
            switch result {
            case let .Ok(json):
                do {
                    try appNetworkState.saveToken(json)
                    completion(result)
                } catch {
                    completion(.Error(error))
                }
            case .Error:
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
        NSURLCache.sharedURLCache().removeAllCachedResponses()
        appNetworkState.deleteToken()
        appNetworkState.deleteClient()
    }

}


extension UIDevice {

    static var isSimulator: Bool {
        return NSProcessInfo.processInfo().environment.keys.contains("SIMULATOR_DEVICE_NAME")
    }

    static var currentIdentifier: String {
        if isSimulator {
            return "5F21210D-3600-418E-BF37-ABA206DD0AFF"
        } else {
            return UIDevice.currentDevice().identifierForVendor!.UUIDString
        }
    }

}
