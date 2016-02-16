//
//  Network.swift
//  NetworkStack
//
//  Created by Ben Norris on 2/8/16.
//  Copyright © 2016 OC Tanner. All rights reserved.
//

import Foundation
import JaSON

// TODO: Add basic error handling for HTML error codes

public struct Network {
    
    // MARK: - Error
    
    public enum Error: ErrorType, CustomStringConvertible {
        case AuthenticationRequired
        case InvalidEndpoint
        case MissingAppNetworkState
        
        public var description: String {
            switch self {
            case .AuthenticationRequired:
                return "You must authenticate to continue."
            case .InvalidEndpoint:
                return "The endpoint you are trying to access is not valid."
            case .MissingAppNetworkState:
                return "The app environment is not configured correctly."
            }
        }
    }
    
    
    // MARK: - Enums
    
    enum RequestType: String {
        case POST
        case PATCH
        case PUT
        case DELETE
    }
    
    
    // MARK: - Public API
    
    public func get(url: NSURL, session: NSURLSession, parameters: JSONObject?, completion: (responseObject: JSONObject?, error: ErrorType?) -> Void) {
        let _url: NSURL
        let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: true)
        components?.queryItems = queryItems(parameters)
        if let componentURL = components?.URL {
            _url = componentURL
        } else {
            _url = url
        }
        let task = session.dataTaskWithURL(_url) { data, response, error in
            let responseObject = self.parseResponse(data)
            dispatch_async(dispatch_get_main_queue()) {
                completion(responseObject: responseObject, error: error)
            }
        }
        task.resume()
    }
    
    public func post(url: NSURL, session: NSURLSession, parameters: JSONObject?, completion: (responseObject: JSONObject?, error: ErrorType?) -> Void) {
        performNetworkCall(.POST, url: url, session: session, parameters: parameters, completion: completion)
    }
    
    public func patch(url: NSURL, session: NSURLSession, parameters: JSONObject?, completion: (responseObject: JSONObject?, error: ErrorType?) -> Void) {
        performNetworkCall(.PATCH, url: url, session: session, parameters: parameters, completion: completion)
    }

    public func put(url: NSURL, session: NSURLSession, parameters: JSONObject?, completion: (responseObject: JSONObject?, error: ErrorType?) -> Void) {
        performNetworkCall(.PUT, url: url, session: session, parameters: parameters, completion: completion)
    }

    public func delete(url: NSURL, session: NSURLSession, completion: (responseObject: JSONObject?, error: ErrorType?) -> Void) {
        performNetworkCall(.DELETE, url: url, session: session, parameters: nil, completion: completion)
    }

}


// MARK: - Private functions

private extension Network {
    
    func performNetworkCall(requestType: RequestType, url: NSURL, session: NSURLSession, parameters: JSONObject?, completion: (responseObject: JSONObject?, error: ErrorType?) -> Void) {
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = requestType.rawValue
        request.HTTPBody = parameterData(parameters)
        
        let task = session.dataTaskWithRequest(request) { data, response, error in
            let responseObject = self.parseResponse(data)
            dispatch_async(dispatch_get_main_queue()) {
                completion(responseObject: responseObject, error: error)
            }
        }
        task.resume()
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
