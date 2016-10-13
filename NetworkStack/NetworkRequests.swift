//
//  NetworkRequests.swift
//  NetworkStack
//
//  Created by Ben Norris on 2/8/16.
//  Copyright © 2016 OC Tanner. All rights reserved.
//

import Foundation
import Marshal

public protocol NetworkRequests {
    func get(from endpoint: String, with parameters: JSONObject?, completion: @escaping Network.ResponseCompletion)
    func post(to endpoint: String, with parameters: JSONObject?, completion: @escaping Network.ResponseCompletion)
    func patch(to endpoint: String, with parameters: JSONObject?, completion: @escaping Network.ResponseCompletion)
    func put(to endpoint: String, with parameters: JSONObject?, completion: @escaping Network.ResponseCompletion)
    func delete(at endpoint: String, completion: @escaping Network.ResponseCompletion)
}

public struct NetworkAPIRequests: NetworkRequests {
    
    // MARK: - Properties
    
    var network = Network()
    
    fileprivate var defaultSession: URLSession? {
        guard let appNetworkState = AppNetworkState.currentAppState else { return nil }
        guard let accessToken = appNetworkState.accessToken else { return nil }
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = ["content-type": "application/json", "Authorization": "Bearer \(accessToken)"]
        configuration.timeoutIntervalForRequest = 10.0
        return URLSession(configuration: configuration)
    }

    fileprivate var activeSession: URLSession? {
        return overrideSession ?? defaultSession
    }
    
    public var overrideSession: URLSession?

    
    // MARK: - Initializers
    
    public init() { }
    
    
    // MARK: - Public API
    
    public func get(from endpoint: String, with parameters: JSONObject?, completion: @escaping Network.ResponseCompletion) {
        do {
            let (session, url) = try config(endpoint: endpoint)
            network.get(from: url, using: session, with: parameters, completion: completion)
        }
        catch {
            completion(.error(error))
        }
    }
    
    public func post(to endpoint: String, with parameters: JSONObject?, completion: @escaping Network.ResponseCompletion) {
        do {
            let (session, url) = try config(endpoint: endpoint)
            network.post(to: url, using: session, with: parameters, completion: completion)
        }
        catch {
            completion(.error(error))
        }
    }
    
    public func patch(to endpoint: String, with parameters: JSONObject?, completion: @escaping Network.ResponseCompletion) {
        do {
            let (session, url) = try config(endpoint: endpoint)
            network.patch(to: url, using: session, with: parameters, completion: completion)
        }
        catch {
            completion(.error(error))
        }
    }
    
    public func put(to endpoint: String, with parameters: JSONObject?, completion: @escaping Network.ResponseCompletion) {
        do {
            let (session, url) = try config(endpoint: endpoint)
            network.put(to: url, using: session, with: parameters, completion: completion)
        }
        catch {
            completion(.error(error))
        }
    }
    
    public func delete(at endpoint: String, completion: @escaping Network.ResponseCompletion) {
        do {
            let (session, url) = try config(endpoint: endpoint)
            network.delete(at: url, using: session, completion: completion)
        }
            
        catch {
            completion(.error(error))
        }
    }
    

    // MARK: - Private functions

    /// - Precondition: `AppNetworkState.currentAppState` must not be nil
    private func config(endpoint: String) throws -> (session: URLSession, url: URL) {
        guard let appNetworkState = AppNetworkState.currentAppState else { fatalError("Must configure current app state to config") }
        guard let session = activeSession else { throw NetworkError.status(status: 401, message: [ "statusMessage": "Networking stack is misconfigured. Restart the app."]) }
        guard let url = appNetworkState.urlForEndpoint(endpoint) else { throw NetworkError.malformedEndpoint(endpoint: endpoint) }
        return (session, url)
    }
    
}
