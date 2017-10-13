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
    func hyperGet(from endpoint: String, with parameters: JSONObject?, completion: @escaping Network.ResponseCompletion)
    func get(from components: NSURLComponents, completion: @escaping Network.ResponseCompletion)
    func post(to endpoint: String, with parameters: JSONObject?, completion: @escaping Network.ResponseCompletion)
    func patch(to endpoint: String, with parameters: JSONObject?, completion: @escaping Network.ResponseCompletion)
    func put(to endpoint: String, with parameters: JSONObject?, completion: @escaping Network.ResponseCompletion)
    func delete(at endpoint: String, completion: @escaping Network.ResponseCompletion)
}

public struct NetworkAPIRequests: NetworkRequests {

    // MARK: - Properties

    var network = Network()

    fileprivate func defaultSession() throws -> URLSession? {
        guard let appNetworkState = AppNetworkState.currentAppState else { return nil }
        guard let accessToken = try appNetworkState.accessToken() else { return nil }
        let configuration = URLSessionConfiguration.default

        let headers: [String:String] = [
            "Accept": "application/json",
            "Authorization": "Bearer \(accessToken)",
            "Accept-Language": Bundle.main.acceptLanguages,
            "X-Client-Id": appNetworkState.appVersionSlug,
            "X-Hydrate": "true"
        ]
        configuration.httpAdditionalHeaders = headers

        configuration.timeoutIntervalForRequest = 10.0
        return URLSession(configuration: configuration)
    }

    fileprivate func activeSession() throws -> URLSession? {
        if overrideSession != nil {
            return overrideSession
        }
        return try defaultSession()
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
            completion(.error(error), nil)
        }
    }

    public func hyperGet(from endpoint: String, with parameters: JSONObject?, completion: @escaping Network.ResponseCompletion) {
        do {
            let result = try self.config(endpoint: endpoint)
            var session = result.session
            let config = result.session.configuration
            if var headers = config.httpAdditionalHeaders {
                headers["Accept"] = "application/hyper+json"
                config.httpAdditionalHeaders = headers
                session = URLSession(configuration: config)
            }
            network.get(from: result.url, using: session, with: parameters, completion: completion)
        }
        catch {
            completion(.error(error), nil)
        }
    }

    public func get(from components: NSURLComponents, completion: @escaping Network.ResponseCompletion) {
        do {
            let (session, url) = try config(endpoint: components.path ?? "")
            components.path = url.absoluteString
            network.get(from: components, using: session, completion: completion)
        } catch {
            completion(.error(error), nil)
        }
    }

    public func post(to endpoint: String, with parameters: JSONObject?, completion: @escaping Network.ResponseCompletion) {
        do {
            let (session, url) = try config(endpoint: endpoint)
            network.post(to: url, using: session, with: parameters, completion: completion)
        }
        catch {
            completion(.error(error), nil)
        }
    }

    public func patch(to endpoint: String, with parameters: JSONObject?, completion: @escaping Network.ResponseCompletion) {
        do {
            let (session, url) = try config(endpoint: endpoint)
            network.patch(to: url, using: session, with: parameters, completion: completion)
        }
        catch {
            completion(.error(error), nil)
        }
    }

    public func put(to endpoint: String, with parameters: JSONObject?, completion: @escaping Network.ResponseCompletion) {
        do {
            let (session, url) = try config(endpoint: endpoint)
            network.put(to: url, using: session, with: parameters, completion: completion)
        }
        catch {
            completion(.error(error), nil)
        }
    }

    public func delete(at endpoint: String, completion: @escaping Network.ResponseCompletion) {
        do {
            let (session, url) = try config(endpoint: endpoint)
            network.delete(at: url, using: session, completion: completion)
        }

        catch {
            completion(.error(error), nil)
        }
    }


    // MARK: - Private functions

    /// - Precondition: `AppNetworkState.currentAppState` must not be nil
    private func config(endpoint: String) throws -> (session: URLSession, url: URL) {
        guard let appNetworkState = AppNetworkState.currentAppState else { fatalError("Must configure current app state to config") }
        guard let session = try activeSession() else { throw NetworkError.status(status: 401, message: [ "statusMessage": "Networking stack is misconfigured. Restart the app."]) }
        guard let url = appNetworkState.urlForEndpoint(endpoint) else { throw NetworkError.malformedEndpoint(endpoint: endpoint) }
        return (session, url)
    }

}
