//
//  Network.swift
//  NetworkStack
//
//  Created by Ben Norris on 2/8/16.
//  Copyright © 2016 OC Tanner. All rights reserved.
//

import Foundation
import Marshal

// MARK: - Error

public enum NetworkError: Error, CustomStringConvertible {
    
    /// Attempted to request a malformed API endpoint
    case malformedEndpoint(endpoint: String)
    
    /// Recieved an invalid response from the server.
    case responseNotValidHTTP
    
    /// HTTP Error status code
    case status(status: Int)
    
    /// Response came back with no data
    case noData
    
    /// Response timed out
    case timeout
    
    public var description: String {
        switch self {
        case .malformedEndpoint(let endpoint):
            return "Attempted to request a malformed API endpoint: \(endpoint)"
        case .responseNotValidHTTP:
            return "Response was not an HTTP Response."
        case .status(let status):
            let errorMessage = HTTPURLResponse.localizedString(forStatusCode: status)
            return "\(status) \(errorMessage)"
        case .noData:
            return "Response returned with no data"
        case .timeout:
            return "Response timed out"
        }
    }
    
}


public struct Network {
    
    public typealias ResponseCompletion = (Result<JSONObject>) -> Void
    
    
    // MARK: - Enums
    
    enum RequestType: String {
        case get
        case post
        case patch
        case put
        case delete
    }
    
    
    // MARK: - Initializers
    
    public init() { }
    
    
    // MARK: - Public API
    
    public func get(from url: URL, using session: URLSession, with parameters: JSONObject?, completion: @escaping Network.ResponseCompletion) {
        let _url: URL
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        components?.queryItems = queryItems(parameters)
        if let componentURL = components?.url {
            _url = componentURL
        } else {
            _url = url
        }
        perform(action: .get, at: _url, using: session, with: nil, completion: completion)
    }
    
    public func post(to url: URL, using session: URLSession, with parameters: JSONObject?, completion: @escaping Network.ResponseCompletion) {
        perform(action: .post, at: url, using: session, with: parameters, completion: completion)
    }
    
    public func patch(to url: URL, using session: URLSession, with parameters: JSONObject?, completion: @escaping Network.ResponseCompletion) {
        perform(action: .patch, at: url, using: session, with: parameters, completion: completion)
    }

    public func put(to url: URL, using session: URLSession, with parameters: JSONObject?, completion: @escaping Network.ResponseCompletion) {
        perform(action: .put, at: url, using: session, with: parameters, completion: completion)
    }

    public func delete(at url: URL, using session: URLSession, completion: @escaping Network.ResponseCompletion) {
        perform(action: .delete, at: url, using: session, with: nil, completion: completion)
    }

    
    // MARK: - Private functions
    
    private func perform(action requestType: RequestType, at url: URL, using session: URLSession, with parameters: JSONObject?, completion: @escaping Network.ResponseCompletion) {
        var request = URLRequest(url: url)
        request.httpMethod = requestType.rawValue
        do {
            request.httpBody = try parameters?.jsonData()
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        } catch {
            completion(.error(error))
            return
        }

        
        if NSProcessInfo.processInfo().environment["networkDebug"] == "YES" {
            var body = ""
            if let data = request.HTTPBody {
                body = String(data: data, encoding: NSUTF8StringEncoding)!
            }
            var command = ""
            if let headers = session.configuration.HTTPAdditionalHeaders, auth = headers["Authorization"] {
                command = "\(NSDate()): curl -H 'Authorization: \(auth)' -H 'Content-Type: application/json' -X \(requestType.rawValue) -d '\(body)' \(request.URL!)"
            } else {
                command = "\(NSDate()): curl -H 'Content-Type: application/json' -X \(requestType.rawValue) -d '\(body)' \(request.URL!)"
            }
            print(command)
        }
        let task = session.dataTask(with: request, completionHandler: { data, response, error in
            if let error = error as? NSError, error.code == NSURLErrorTimedOut {
                self.finalizeNetworkCall(result: .error(NetworkError.timeout), completion: completion)
                return
            }
            guard let response = response as? HTTPURLResponse else {
                self.finalizeNetworkCall(result: .error(NetworkError.responseNotValidHTTP), completion: completion)
                return
            }
            if case let status = response.statusCode , status >= 200 && status < 300 {
                guard let data = data else {
                    self.finalizeNetworkCall(result: .error(NetworkError.noData), completion: completion)
                    return
                }
                do {
                    if data.count > 0 {
                        let responseObject = try JSONParser.JSONObjectGuaranteed(with: data)
                        self.finalizeNetworkCall(result: .ok(responseObject), completion: completion)
                    } else {
                        self.finalizeNetworkCall(result: .ok(JSONObject()), completion: completion)
                    }
                }
                catch {
                    self.finalizeNetworkCall(result: .error(error), completion: completion)
                }
                
                
            } else {
                if NSProcessInfo.processInfo().environment["networkDebug"] == "YES" {
                    if let data = data {
                        print(String(data: data, encoding: NSUTF8StringEncoding))
                    }
                }
                let networkError = NetworkError.status(status: response.statusCode)
                self.finalizeNetworkCall(result: .error(networkError), completion: completion)
            }
        }) 
        task.resume()
    }
    
    func finalizeNetworkCall(result: Result<JSONObject>, completion: @escaping Network.ResponseCompletion) {
        DispatchQueue.main.async {
            completion(result)
        }
    }
    
    func queryItems(_ parameters: JSONObject?) -> [URLQueryItem]? {
        if let parameters = parameters {
            var queryItems = [URLQueryItem]()
            for (name, value) in parameters {
                let queryItem = URLQueryItem(name: name, value: String(describing: value))
                queryItems.append(queryItem)
            }
            return queryItems
        }
        return nil
    }
    
}


private extension JSONParser {
    
    static func JSONObjectGuaranteed(with data: Data) throws -> JSONObject {
        let obj: Any = try JSONSerialization.jsonObject(with: data, options: [])
        if let array = obj as? [JSONObject] {
            return [ "data": array ]
        } else {
            return try JSONObject.value(from: obj)
        }
    }
    
}
