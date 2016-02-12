//
//  Network.swift
//  NetworkStack
//
//  Created by Ben Norris on 2/8/16.
//  Copyright © 2016 OC Tanner. All rights reserved.
//

import Foundation
import JaSON

public struct Network {
    
    // MARK: - Error
    
    enum Error: ErrorType {
        case AuthenticationRequired
        case InvalidEndpoint
    }
    
    
    // MARK: - Public API
    
    public func get(url: NSURL, session: NSURLSession, parameters: JSONObject?, completion: (responseObject: JSONObject?, error: ErrorType?) -> Void) {
        let _url: NSURL
        let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems(parameters)
        if let componentURL = components?.URL {
            _url = componentURL
        } else {
            _url = url
        }
        let task = session.dataTaskWithURL(_url) { data, response, error in
            let responseObject = self.parseResponse(data)
            completion(responseObject: responseObject, error: error)
        }
        task.resume()
    }
    
    public func post(url: NSURL, session: NSURLSession, parameters: JSONObject?, completion: (responseObject: JSONObject?, error: ErrorType?) -> Void) {
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        request.HTTPBody = parameterData(parameters)
        
        let task = session.dataTaskWithRequest(request) { data, response, error in
            let responseObject = self.parseResponse(data)
            completion(responseObject: responseObject, error: error)
        }
        task.resume()
    }
    
    public func patch(url: NSURL, session: NSURLSession, parameters: JSONObject?, completion: (responseObject: JSONObject?, error: ErrorType?) -> Void) {
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "PATCH"
        request.HTTPBody = parameterData(parameters)
        
        let task = session.dataTaskWithRequest(request) { data, response, error in
            let responseObject = self.parseResponse(data)
            completion(responseObject: responseObject, error: error)
        }
        task.resume()
    }
    
}


// MARK: - Private functions

private extension Network {
    
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
        if let queryItems = queryItems(parameters) {
            return NSKeyedArchiver.archivedDataWithRootObject(queryItems)
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
