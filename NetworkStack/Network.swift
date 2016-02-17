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

public struct Network {
    
    // MARK: - Error
    
    public enum Error: ErrorType, CustomStringConvertible {
        case AuthenticationRequired
        case InvalidEndpoint
        case MissingAppNetworkState
        case ResponseNotValidHTTP
        case Status500
        case Status404
        case Status403
        case Status400
        case UnknownNetworkError(status: Int)
        
        public var description: String {
            switch self {
            case .AuthenticationRequired:
                return "Hold up! Log in to continue."
            case .InvalidEndpoint:
                return "Oops. Your request made no sense."
            case .MissingAppNetworkState:
                return "What the!? How did you even get here?"
            case .ResponseNotValidHTTP:
                return "Yikes. The server’s talking back to you."
            case .Status500:
                return "Ugh. Internal server error. (Code 500)"
            case .Status404:
                return "Uh oh. There’s nothing here. (Code 404)"
            case .Status403:
                return "Ah ah ah. You don’t have access. (Code 403)"
            case .Status400:
                return "Oops. Your request made no sense. (Code 400)"
            case .UnknownNetworkError(let status):
                return "Hmm. Something’s wrong. (Code \(status))"
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
                self.finalizeNetworkCall(responseObject: responseObject, error: error, completion: completion)
            } else {
                var customNetworkError: Error?
                let status = response.statusCode
                if status == 500 {
                    customNetworkError = .Status500
                } else if status == 404 {
                    customNetworkError = .Status404
                } else if status == 403 {
                    customNetworkError = .Status403
                } else if status == 401 {
                    customNetworkError = .AuthenticationRequired
                } else if status == 400 {
                    customNetworkError = .Status400
                } else if error == nil {
                    customNetworkError = .UnknownNetworkError(status: status)
                }
                self.finalizeNetworkCall(responseObject: nil, error: customNetworkError ?? error, completion: completion)
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
