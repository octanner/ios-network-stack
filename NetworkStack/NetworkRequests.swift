//
//  NetworkRequests.swift
//  NetworkStack
//
//  Created by Ben Norris on 2/8/16.
//  Copyright © 2016 OC Tanner. All rights reserved.
//

import Foundation
import JaSON


// TODO: Bring functionality in here to construct the default session and pass it to Network, lowercase method names, add delete, add put, change parameters to [String: AnyObject]? (encode the value as a String) (look at Alamofire for examples of eventual encoding)

public protocol APIRequests {
    func get(endpoint: String, parameters: JSONObject?, completion: (responseObject: JSONObject?, error: ErrorType?) -> Void) throws
    func post(endpoint: String, parameters: JSONObject?, completion: (responseObject: JSONObject?, error: ErrorType?) -> Void) throws
    func patch(endpoint: String, parameters: JSONObject?, completion: (responseObject: JSONObject?, error: ErrorType?) -> Void) throws
}

public struct NetworkAPIRequests: APIRequests {
    
    // MARK: - Initializers
    
    public init(appState: AppStateRepresentable) {
        self.appState = appState
    }
    
    
    // MARK: - Internal properties
    
    var network = Network()
    
    
    // MARK: - Private properties
    
    private let appState: AppStateRepresentable
    private var defaultSession: NSURLSession? {
        guard let accessToken = appState.accessToken else { return nil }
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = ["Accept": "application/json", "Authorization": "Bearer \(accessToken)"]
        configuration.timeoutIntervalForRequest = 10.0
        return NSURLSession(configuration: configuration)
    }
    
    
    // MARK: - Public API
    
    public func get(endpoint: String, parameters: JSONObject?, completion: (responseObject: JSONObject?, error: ErrorType?) -> Void) throws {
        guard let session = defaultSession else { throw Network.Error.AuthenticationRequired }
        guard let url = NSURL(string: appState.networkPath + endpoint) else { throw Network.Error.InvalidEndpoint }
        network.get(url, session: session, parameters: parameters, completion: completion)
    }
    
    public func post(endpoint: String, parameters: JSONObject?, completion: (responseObject: JSONObject?, error: ErrorType?) -> Void) throws {
        guard let session = defaultSession else { throw Network.Error.AuthenticationRequired }
        guard let url = NSURL(string: appState.networkPath + endpoint) else { throw Network.Error.InvalidEndpoint }
        network.post(url, session: session, parameters: parameters, completion: completion)
    }
    
    public func patch(endpoint: String, parameters: JSONObject?, completion: (responseObject: JSONObject?, error: ErrorType?) -> Void) throws {
        guard let session = defaultSession else { throw Network.Error.AuthenticationRequired }
        guard let url = NSURL(string: appState.networkPath + endpoint) else { throw Network.Error.InvalidEndpoint }
        network.patch(url, session: session, parameters: parameters, completion: completion)
    }
    
}
