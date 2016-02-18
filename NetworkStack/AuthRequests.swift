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
    func logIn(username: String, password: String, completion: Network.ResponseCompletion) throws
    func logOut()
}

public struct AuthAPIRequests: AuthRequests {

    // MARK: - Public initializer

    public init() { }

    
    // MARK: - Internal properties
    
    var network = Network()
    
    
    // MARK: - Public API
    
    /// - Precondition: `AppNetworkState.currentAppState` must not be nil
    public func logIn(username: String, password: String, completion: Network.ResponseCompletion) throws {
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
        
        network.post(url, session: session, parameters: parameters) { responseObject, networkError in
            if let responseObject = responseObject {
                do {
                    try appNetworkState.saveToken(responseObject)
                    completion(responseObject: responseObject, error: nil)
                } catch {
                    completion(responseObject: nil, error: error)
                }
            } else {
                completion(responseObject: nil, error: networkError)
            }
        }
    }
    
    public func logOut() {
        guard let appNetworkState = AppNetworkState.currentAppState else { return }
        appNetworkState.deleteToken()
    }

}
