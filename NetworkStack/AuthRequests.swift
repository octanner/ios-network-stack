//
//  AuthRequests.swift
//  NetworkStack
//
//  Created by Ben Norris on 2/11/16.
//  Copyright © 2016 OC Tanner. All rights reserved.
//

import Foundation
import JaSON

public protocol AuthRequests {
    func authenticate(username: String, password: String, completion: Network.ResponseCompletion) throws
    func authenticate(pairingCode: String, completion: Network.ResponseCompletion) throws
    func authenticate(tokenJSON: JSONObject) throws
    func logOut()
}

public struct AuthAPIRequests: AuthRequests {

    // MARK: - Public initializer

    public init() { }

    
    // MARK: - Internal properties
    
    var network = Network()
    
    
    // MARK: - Public API
    
    /// - Precondition: `AppNetworkState.currentAppState` must not be nil
    public func authenticate(username: String, password: String, completion: Network.ResponseCompletion) throws {
        guard let appNetworkState = AppNetworkState.currentAppState else { fatalError("Must configure current app state to log in") }
        guard let url = NSURL(string: appNetworkState.tokenEndpointURLString) else { throw Network.Error.MalformedEndpoint(endpoint: appNetworkState.tokenEndpointURLString) }
        let parameters = [
            "grant_type": "password",
            "username": username,
            "password": password
        ]
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = ["content-type": "application/json"]
        configuration.timeoutIntervalForRequest = 10.0
        let session = NSURLSession(configuration: configuration)
        
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
    public func authenticate(pairingCode: String, completion: Network.ResponseCompletion) throws {
        guard let deviceUUID = UIDevice.currentDevice().identifierForVendor else { fatalError("Device must have an identifier to log in") }
        guard let appNetworkState = AppNetworkState.currentAppState else { fatalError("Must configure current app state to log in") }
        guard let url = NSURL(string: appNetworkState.tokenEndpointURLString) else { throw Network.Error.MalformedEndpoint(endpoint: appNetworkState.tokenEndpointURLString) }
        let parameters = [
            "client_id": pairingCode,
            "grant_type": "device",
            "device_id" : deviceUUID.UUIDString,
            "device_name" : UIDevice.currentDevice().name
        ]
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = ["content-type": "application/json"]
        configuration.timeoutIntervalForRequest = 10.0
        let session = NSURLSession(configuration: configuration)
        
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
    
    /// - Precondition: `AppNetworkState.currentAppState` must not be nil
    public func authenticate(tokenJSON: JSONObject) throws {
        guard let appNetworkState = AppNetworkState.currentAppState else { fatalError("Must configure current app state to log in") }
        try appNetworkState.saveToken(tokenJSON)
    }
    
    public func logOut() {
        guard let appNetworkState = AppNetworkState.currentAppState else { return }
        appNetworkState.deleteToken()
    }

}
