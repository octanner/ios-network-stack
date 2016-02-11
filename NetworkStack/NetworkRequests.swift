//
//  NetworkRequests.swift
//  NetworkStack
//
//  Created by Ben Norris on 2/8/16.
//  Copyright © 2016 OC Tanner. All rights reserved.
//

import Foundation
import JaSON

protocol APIRequests {
    func GET(endpoint: String, parameters: [String: String]?, completion: (responseObject: JSONObject?, error: ErrorType?) -> Void)
    func POST(endpoint: String, parameters: [String: String]?, completion: (responseObject: JSONObject?, error: ErrorType?) -> Void)
    func PATCH(endpoint: String, parameters: [String: String]?, completion: (responseObject: JSONObject?, error: ErrorType?) -> Void)
}

struct NetworkAPIRequests: APIRequests {
    
    // MARK: - Initializers
    
    init(appState: AppStateRepresentable) {
        self.network = Network(appState: appState)
    }
    
    
    // MARK: - Internal properties
    
    var network: Network
    
    
    // MARK: - API functions
    
    func GET(endpoint: String, parameters: [String: String]?, completion: (responseObject: JSONObject?, error: ErrorType?) -> Void) {
        network.GET(endpoint, parameters: parameters, completion: completion)
    }
    
    func POST(endpoint: String, parameters: [String: String]?, completion: (responseObject: JSONObject?, error: ErrorType?) -> Void) {
        network.POST(endpoint, parameters: parameters, completion: completion)
    }
    
    func PATCH(endpoint: String, parameters: [String: String]?, completion: (responseObject: JSONObject?, error: ErrorType?) -> Void) {
        network.PATCH(endpoint, parameters: parameters, completion: completion)
    }
    
}
