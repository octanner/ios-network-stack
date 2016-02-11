//
//  Network.swift
//  NetworkStack
//
//  Created by Ben Norris on 2/8/16.
//  Copyright © 2016 OC Tanner. All rights reserved.
//

import Foundation
import JaSON

public protocol AppStateRepresentable {
    var accessToken: String? { get }
    var loggedIn: Bool { get }
    var networkPath: String { get }
    func saveToken(json: JSONObject) throws
    func deleteToken()
}

public struct Network {
    
    // MARK: - Initializers
    
    public init(appState: AppStateRepresentable) {
        self.appState = appState
    }
    
    
    // MARK: - Private properties
    
    private let appState: AppStateRepresentable
    private var defaultSession: NSURLSession! {
        guard let accessToken = appState.accessToken else { return nil }
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = ["Accept": "application/json", "Authorization": "Bearer \(accessToken)"]
        configuration.timeoutIntervalForRequest = 10.0
        return NSURLSession(configuration: configuration)
    }
    
    
    // MARK: - Public API
    
    public func logIn(username: String, password: String, completion: (success: Bool, error: ErrorType?) -> Void) {
        let parameters = [
            "grant_type": "password",
            "email": username,
            "password": password
        ]
        guard let components = URLComponents("/oauth/token", parameters: parameters), URL = components.URL else { fatalError("Invalid URL") }
        let request = NSMutableURLRequest(URL: URL)
        request.HTTPMethod = "POST"
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.timeoutIntervalForRequest = 10.0
        let session = NSURLSession(configuration: configuration)
        
        let task = session.dataTaskWithRequest(request) { data, response, networkError in
            if let responseObject = self.parseResponse(data) {
                do {
                    try self.appState.saveToken(responseObject)
                    completion(success: true, error: nil)
                } catch {
                    completion(success: false, error: error)
                }
            } else {
                completion(success: false, error: networkError)
            }
        }
        task.resume()
    }
    
    public func logOut() {
        appState.deleteToken()
    }
    
    public func GET(endpoint: String, parameters: [String: String]?, completion: (responseObject: JSONObject?, error: ErrorType?) -> Void) {
        if appState.accessToken == nil {
            // TODO: Force authentication
        }
        guard let components = URLComponents(endpoint, parameters: parameters), URL = components.URL else { fatalError("Invalid URL") }
        let task = defaultSession.dataTaskWithURL(URL) { data, response, error in
            let responseObject = self.parseResponse(data)
            completion(responseObject: responseObject, error: error)
        }
        task.resume()
    }
    
    public func POST(endpoint: String, parameters: [String: String]?, completion: (responseObject: JSONObject?, error: ErrorType?) -> Void) {
        if appState.accessToken == nil {
            // TODO: Force authentication
        }
        guard let baseURL = NSURL(string: appState.networkPath), URL = NSURL(string: endpoint, relativeToURL: baseURL) else { fatalError("Invalid URL") }
        let paramData = parameterData(parameters)
        let request = NSMutableURLRequest(URL: URL)
        request.HTTPMethod = "POST"
        
        let handler: (NSData?, NSURLResponse?, NSError?) -> () =  { data, response, error in
            let responseObject = self.parseResponse(data)
            completion(responseObject: responseObject, error: error)
        }
        
        let task = defaultSession.uploadTaskWithRequest(request, fromData: paramData, completionHandler: handler)
        task.resume()
    }
    
    public func PATCH(endpoint: String, parameters: [String: String]?, completion: (responseObject: JSONObject?, error: ErrorType?) -> Void) {
        if appState.accessToken == nil {
            // TODO: Force authentication
        }
        guard let baseURL = NSURL(string: appState.networkPath), URL = NSURL(string: endpoint, relativeToURL: baseURL) else { fatalError("Invalid URL") }
        let request = NSMutableURLRequest(URL: URL)
        request.HTTPMethod = "PATCH"
        let paramData = parameterData(parameters)
        let task = defaultSession.uploadTaskWithRequest(request, fromData: paramData) { data, response, error in
            let responseObject = self.parseResponse(data)
            completion(responseObject: responseObject, error: error)
        }
        task.resume()
    }
    
}


// MARK: - Private functions

private extension Network {
    
    func URLComponents(endpoint: String, parameters: [String: String]?) -> NSURLComponents? {
        let components = NSURLComponents(string: appState.networkPath + endpoint)
        components?.queryItems = queryItems(parameters)
        return components
    }
    
    func queryItems(parameters: [String: String]?) -> [NSURLQueryItem]? {
        if let parameters = parameters {
            var queryItems = [NSURLQueryItem]()
            for (name, value) in parameters {
                let queryItem = NSURLQueryItem(name: name, value: value)
                queryItems.append(queryItem)
            }
            return queryItems
        }
        return nil
    }
    
    func parameterData(parameters: [String : String]?) -> NSData? {
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
