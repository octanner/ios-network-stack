//
//  AuthRequests.swift
//  NetworkStack
//
//  Created by Ben Norris on 2/11/16.
//  Copyright © 2016 OC Tanner. All rights reserved.
//

import Foundation

protocol AuthRequests {
    func logIn(username: String, password: String, completion: (success: Bool, error: ErrorType?) -> Void)
    func logOut()
}

struct AuthAPIRequests: AuthRequests {
    
    // MARK: - Initializers
    
    init(appState: AppStateRepresentable) {
        self.network = Network(appState: appState)
    }
    
    
    // MARK: - Internal properties
    
    var network: Network
    
    
    // MARK: - Auth functions
    
    func logIn(username: String, password: String, completion: (success: Bool, error: ErrorType?) -> Void) {
        network.logIn(username, password: password, completion: completion)
    }
    
    func logOut() {
        network.logOut()
    }
}
