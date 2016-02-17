//
//  Network.swift
//  NetworkStack
//
//  Created by Ben Norris on 2/8/16.
//  Copyright © 2016 OC Tanner. All rights reserved.
//

import Foundation
import JaSON

public typealias NetworkResponseCompletion = (responseObject: JSONObject?, error: ErrorType?) -> Void

private let KnownErrorStatusCodes = [
    400: "Bad Request",
    401: "Authentication Required",
    403: "Forbidden",
    404: "Not Found",
    500: "Internal Server Error",
]

public struct Network {
    
    // MARK: - Error
    
    public enum Error: ErrorType, CustomStringConvertible {
        case InvalidEndpoint(endpoint: String)
        case MissingAppNetworkState
        case ResponseNotValidHTTP
        case Status(status: Int)
        
        public var description: String {
            switch self {
            case .InvalidEndpoint(let endpoint):
                return "Invalid endpoint: \(endpoint)"
            case .MissingAppNetworkState:
                return "No current network state. Make sure AppNetworkState.currentAppState is set."
            case .ResponseNotValidHTTP:
                return "Response was not an HTTP Response."
            case .Status(let status):
                if let errorMessage = KnownErrorStatusCodes[status] {
                    return "\(status) \(errorMessage)"
                }
                else {
                    return "Unknown Network Error. Status: \(status))"
                }
            }
        }
    }
    
    
    // MARK: - Enums
    
    enum RequestType: String {
        case GET
        case POST
        case PATCH
        case PUT
        case DELETE
    }
    
    
    // MARK: - Public API
    
    public func get(url: NSURL, session: NSURLSession, parameters: JSONObject?, completion: NetworkResponseCompletion) {
        let _url: NSURL
        let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: true)
        components?.queryItems = queryItems(parameters)
        if let componentURL = components?.URL {
            _url = componentURL
        } else {
            _url = url
        }
        performNetworkCall(.GET, url: _url, session: session, parameters: nil, completion: completion)
    }
    
    public func post(url: NSURL, session: NSURLSession, parameters: JSONObject?, completion: NetworkResponseCompletion) {
        performNetworkCall(.POST, url: url, session: session, parameters: parameters, completion: completion)
    }
    
    public func patch(url: NSURL, session: NSURLSession, parameters: JSONObject?, completion: NetworkResponseCompletion) {
        performNetworkCall(.PATCH, url: url, session: session, parameters: parameters, completion: completion)
    }

    public func put(url: NSURL, session: NSURLSession, parameters: JSONObject?, completion: NetworkResponseCompletion) {
        performNetworkCall(.PUT, url: url, session: session, parameters: parameters, completion: completion)
    }

    public func delete(url: NSURL, session: NSURLSession, completion: NetworkResponseCompletion) {
        performNetworkCall(.DELETE, url: url, session: session, parameters: nil, completion: completion)
    }

}


// MARK: - Private functions

private extension Network {
    
    func performNetworkCall(requestType: RequestType, url: NSURL, session: NSURLSession, parameters: JSONObject?, completion: NetworkResponseCompletion) {
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = requestType.rawValue
        request.HTTPBody = parameterData(parameters)
        
        let task = session.dataTaskWithRequest(request) { data, response, error in
            guard let response = response as? NSHTTPURLResponse else {
                self.finalizeNetworkCall(responseObject: nil, error: Error.ResponseNotValidHTTP, completion: completion)
                return
            }
            if case let status = response.statusCode where status >= 200 && status < 300 {
                let responseObject = self.parseResponse(data)
                self.finalizeNetworkCall(responseObject: responseObject, error: nil, completion: completion)
            } else {
                let networkError = Error.Status(status: response.statusCode)
                self.finalizeNetworkCall(responseObject: nil, error: networkError, completion: completion)
            }
        }
        task.resume()
    }
    
    func finalizeNetworkCall(responseObject responseObject: JSONObject?, error: ErrorType?, completion: NetworkResponseCompletion) {
        dispatch_async(dispatch_get_main_queue()) {
            completion(responseObject: responseObject, error: error)
        }
    }
    
    func queryItems(parameters: JSONObject?) -> [NSURLQueryItem]? {
        if let parameters = parameters {
            var queryItems = [NSURLQueryItem]()
            for (name, value) in parameters {
                let queryItem = NSURLQueryItem(name: name, value: String(value))
                queryItems.append(queryItem)
            }
            return queryItems
        }
        return nil
    }
    
    func parameterData(parameters: JSONObject?) -> NSData? {
        if let parameters = parameters {
            var adjustedParameters = [String: String]()
            for (name, value) in parameters {
                adjustedParameters[name] = String(value)
            }
            return try? NSJSONSerialization.dataWithJSONObject(adjustedParameters, options: [])
        }
        return nil
    }
    
    func parseResponse(data: NSData?) -> JSONObject? {
        if let data = data {
            if let json = try? NSJSONSerialization.JSONObjectWithData(data, options: [NSJSONReadingOptions.AllowFragments]) {
                return json as? JSONObject
            }
        }
        return nil
    }
    
}
