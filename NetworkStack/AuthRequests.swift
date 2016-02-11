//
//  AuthRequests.swift
//  NetworkStack
//
//  Created by Ben Norris on 2/11/16.
//  Copyright © 2016 OC Tanner. All rights reserved.
//

import Foundation

public protocol AuthRequests {
    func logIn(username: String, password: String, completion: (success: Bool, error: ErrorType?) -> Void)
    func logOut()
}

public struct AuthAPIRequests: AuthRequests {
    
    // MARK: - Initializers
    
    public init(appState: AppStateRepresentable) {
        self.network = Network(appState: appState)
    }
    
    
    // MARK: - Internal properties
    
    var network: Network
    
    
    // MARK: - Auth functions
    
    public func logIn(username: String, password: String, completion: (success: Bool, error: ErrorType?) -> Void) {
        network.logIn(username, password: password, completion: completion)
    }
    
    public func logOut() {
        network.logOut()
    }
}
