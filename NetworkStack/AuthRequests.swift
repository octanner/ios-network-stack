//
//  AuthRequests.swift
//  NetworkStack
//
//  Created by Ben Norris on 2/11/16.
//  Copyright © 2016 OC Tanner. All rights reserved.
//

import Foundation


// TODO: This should just call network for something like login and construct the session and pass the URL in

public protocol AuthRequests {
    func logIn(endpoint endpoint: String, username: String, password: String, completion: (success: Bool, error: ErrorType?) -> Void) throws
    func logOut()
}

public struct AuthAPIRequests: AuthRequests {
    
    // MARK: - Initializers
    
    public init(appState: AppStateRepresentable) {
        self.appState = appState
    }
    
    
    // MARK: - Internal properties
    
    var network = Network()
    
    
    // MARK: - Private properties
    
    private let appState: AppStateRepresentable
    
    
    // MARK: - Public API
    
    public func logIn(endpoint endpoint: String, username: String, password: String, completion: (success: Bool, error: ErrorType?) -> Void) throws {
        guard let url = NSURL(string: appState.networkPath + endpoint) else { throw Network.Error.InvalidEndpoint }
        let parameters = [
            "grant_type": "password",
            "email": username,
            "password": password
        ]
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.timeoutIntervalForRequest = 10.0
        let session = NSURLSession(configuration: configuration)
        
        network.post(url, session: session, parameters: parameters, completion: { responseObject, networkError in
            if let responseObject = responseObject {
                do {
                    try self.appState.saveToken(responseObject)
                    completion(success: true, error: nil)
                } catch {
                    completion(success: false, error: error)
                }
            } else {
                completion(success: false, error: networkError)
            }
        })
    }
    
    public func logOut() {
        appState.deleteToken()
    }

}
