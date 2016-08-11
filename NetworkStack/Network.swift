//
//  Network.swift
//  NetworkStack
//
//  Created by Ben Norris on 2/8/16.
//  Copyright © 2016 OC Tanner. All rights reserved.
//

import Foundation
import Marshal

public struct Network {
    
    public typealias ResponseCompletion = Result<JSONObject> -> Void
    
    
    // MARK: - Error
    
    public enum Error: ErrorType, CustomStringConvertible {
        
        /// Attempted to request a malformed API endpoint
        case MalformedEndpoint(endpoint: String)
        
        /// Recieved an invalid response from the server.
        case ResponseNotValidHTTP
        
        /// HTTP Error status code
        case Status(status: Int)
        
        /// Response came back with no data
        case NoData
        
        /// Response timed out
        case Timeout
        
        public var description: String {
            switch self {
            case .MalformedEndpoint(let endpoint):
                return "Attempted to request a malformed API endpoint: \(endpoint)"
            case .ResponseNotValidHTTP:
                return "Response was not an HTTP Response."
            case .Status(let status):
                let errorMessage = NSHTTPURLResponse.localizedStringForStatusCode(status)
                return "\(status) \(errorMessage)"
            case .NoData:
                return "Response returned with no data"
            case .Timeout:
                return "Response timed out"
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
    
    
    // MARK: - Initializers
    
    public init() { }
    
    
    // MARK: - Public API
    
    public func get(url: NSURL, session: NSURLSession, parameters: JSONObject?, completion: Network.ResponseCompletion) {
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
    
    public func post(url: NSURL, session: NSURLSession, parameters: JSONObject?, completion: Network.ResponseCompletion) {
        performNetworkCall(.POST, url: url, session: session, parameters: parameters, completion: completion)
    }
    
    public func patch(url: NSURL, session: NSURLSession, parameters: JSONObject?, completion: Network.ResponseCompletion) {
        performNetworkCall(.PATCH, url: url, session: session, parameters: parameters, completion: completion)
    }

    public func put(url: NSURL, session: NSURLSession, parameters: JSONObject?, completion: Network.ResponseCompletion) {
        performNetworkCall(.PUT, url: url, session: session, parameters: parameters, completion: completion)
    }

    public func delete(url: NSURL, session: NSURLSession, completion: Network.ResponseCompletion) {
        performNetworkCall(.DELETE, url: url, session: session, parameters: nil, completion: completion)
    }

}


// MARK: - Private functions

private extension Network {
    
    func performNetworkCall(requestType: RequestType, url: NSURL, session: NSURLSession, parameters: JSONObject?, completion: Network.ResponseCompletion) {
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = requestType.rawValue
        do {
            request.HTTPBody = try parameters?.jsonData()
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        } catch {
            completion(.Error(error))
            return
        }
        
        let task = session.dataTaskWithRequest(request) { data, response, error in
            if let error = error where error.code == NSURLErrorTimedOut {
                self.finalizeNetworkCall(result: .Error(Error.Timeout), completion: completion)
                return
            }
            guard let response = response as? NSHTTPURLResponse else {
                self.finalizeNetworkCall(result: .Error(Error.ResponseNotValidHTTP), completion: completion)
                return
            }
            if case let status = response.statusCode where status >= 200 && status < 300 {
                guard let data = data else {
                    self.finalizeNetworkCall(result: .Error(Error.NoData), completion: completion)
                    return
                }
                do {
                    if data.length > 0 {
                        let responseObject = try JSONParser.JSONObjectGuaranteed(data)
                        self.finalizeNetworkCall(result: .Ok(responseObject), completion: completion)
                    } else {
                        self.finalizeNetworkCall(result: .Ok(JSONObject()), completion: completion)
                    }
                }
                catch {
                    self.finalizeNetworkCall(result: .Error(error), completion: completion)
                }
                
                
            } else {
                let networkError = Error.Status(status: response.statusCode)
                self.finalizeNetworkCall(result: .Error(networkError), completion: completion)
            }
        }
        task.resume()
    }
    
    func finalizeNetworkCall(result result: Result<JSONObject>, completion: Network.ResponseCompletion) {
        dispatch_async(dispatch_get_main_queue()) {
            completion(result)
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
    
}


private extension JSONParser {
    
    public static func JSONObjectGuaranteed(data: NSData) throws -> JSONObject {
        let obj: Any = try NSJSONSerialization.JSONObjectWithData(data, options: [])
        if let array = obj as? [JSONObject] {
            return [ "data": array ]
        } else {
            return try JSONObject.value(obj)
        }
    }
    
}
