//
//  Network.swift
//  NetworkStack
//
//  Created by Ben Norris on 2/8/16.
//  Copyright © 2016 OC Tanner. All rights reserved.
//

import Foundation
import Marshal
import SwiftyBeaver


// MARK: - Error

public enum NetworkError: LocalizedError {

    /// Attempted to request a malformed API endpoint
    case malformedEndpoint(endpoint: String)

    /// Recieved an invalid response from the server.
    case responseNotValidHTTP

    /// HTTP Error status code
    case status(status: Int, message: JSONObject?)

    /// Response came back with no data
    case noData

    /// Response timed out
    case timeout

    public var errorDescription: String? {
        switch self {
        case .malformedEndpoint(let endpoint):
            return "Attempted to request a malformed API endpoint: \(endpoint)"
        case .responseNotValidHTTP:
            return "Response was not an HTTP Response."
        case .status(let status, let message):
            if let message = message {
                let statusMessage: String? = try? message.value(for: "statusText")
                if let statusMessage = statusMessage {
                    return "\(status) \(statusMessage)"
                }
            }
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

    public typealias ResponseCompletion = (Result<JSONObject>, JSONObject?) -> Void


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

    public func get(from components: NSURLComponents, using session: URLSession, completion: @escaping Network.ResponseCompletion) {
        guard let url: URL = components.url else {
            completion(.error(NetworkError.malformedEndpoint(endpoint: components.path ?? "Unknown")))
            return
        }
        perform(action: .get, at: url, using: session, with: nil, completion: completion)
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
            completion(.error(error), request.allHTTPHeaderFields)
            return
        }

        var headers = request.allHTTPHeaderFields ?? [:]
        let requestId = UUID().uuidString
        headers["X-Request-ID"] = requestId
        switch requestType {
        case .post, .put, .patch:
            headers["Content-Type"] = "application/json"
        case .get, .delete:
            break
        }
        request.allHTTPHeaderFields = headers

        if ProcessInfo.processInfo.environment["networkDebug"] == "YES" {
            var body = ""
            if let data = request.httpBody, request.httpMethod != "GET" && request.httpMethod != "DELETE" {
                body = " -d '\(String(data: data, encoding: .utf8)!)'"
            }
            var command = ""
            var headerValues = [String]()
            if let requestHeaders = request.allHTTPHeaderFields {
                headerValues.append(contentsOf: requestHeaders.map { name, value in "-H '\(name): \(value)'" })
            }
            if let headers = session.configuration.httpAdditionalHeaders {
                headerValues.append(contentsOf: headers.map { name, value in "-H '\(name): \(value)'" })
                command = "\(NSDate()): curl \(headerValues.joined(separator: " ")) -X \(requestType.rawValue.uppercased())\(body) \(request.url!)"
            } else {
                command = "\(NSDate()): curl \(headerValues.joined(separator: " ")) -X \(requestType.rawValue.uppercased())\(body) \(request.url!)"
            }
            print(command)
        }
        let start = Date()
        let task = session.dataTask(with: request, completionHandler: { data, response, error in
            let duration = Int(round(-start.timeIntervalSinceNow * 1000))
            var line = "at=Network.swift method=\(request.httpMethod!) path=\(request.url!.path) host=\(request.url!.host!) request_id=\(request.allHTTPHeaderFields?["X-Request-ID"] ?? "not-found")"
            if duration <= 250 {
                line += " service=\(duration)ms"
            } else if duration <= 500 {
                line += " \u{001b}[35mservice=\(duration)ms\u{001b}[0m"
            } else {
                line += " \u{001b}[31mservice=\(duration)ms\u{001b}[0m"
            }
            if let error = error as NSError?, error.code == NSURLErrorTimedOut {
                line += " \u{001b}[31mstatus=timed-out\u{001b}[0m"
                SwiftyBeaver.error(line)
                self.finalizeNetworkCall(result: .error(NetworkError.timeout), headers: nil, completion: completion)
                return
            }
            guard let response = response as? HTTPURLResponse else {
                line += " \u{001b}[31mstatus=not-valid-http\u{001b}[0m"
                SwiftyBeaver.error(line)
                self.finalizeNetworkCall(result: .error(NetworkError.responseNotValidHTTP), headers: nil, completion: completion)
                return
            }
            let headers = response.allHeaderFields.reduce([String:String]()) { result, pair in
                var dictionary = result
                dictionary[pair.key.description.lowercased()] = "\(pair.value)"
                return dictionary
            }
            let status = response.statusCode
            if status >= 200 && status < 300 {
                line += " status=\(status)"
                guard let data = data else {
                    line += "\u{001b}[31mbytes=0\u{001b}[0m"
                    SwiftyBeaver.error(line)
                    self.finalizeNetworkCall(result: .error(NetworkError.noData), headers: headers, completion: completion)
                    return
                }
                line += " bytes=\(data.count)"
                SwiftyBeaver.info(line)
                do {
                    if data.count > 0 {
						if ProcessInfo.processInfo.environment["networkDebug"] == "YES" {
                            dump(String(data: data, encoding: .utf8))
                        }
                        let responseObject = try JSONParser.JSONObjectGuaranteed(with: data)
                        self.finalizeNetworkCall(result: .ok(responseObject), headers: headers, completion: completion)
                    } else {
                        self.finalizeNetworkCall(result: .ok(JSONObject()), headers: headers, completion: completion)
                    }
                }
                catch {
                    self.finalizeNetworkCall(result: .error(error), headers: headers, completion: completion)
                }


            } else {
                line += " status=\u{001b}[31m\(status)\u{001b}[0m"
                if let data = data {
                    line += " bytes=\(data.count)"
                    if ProcessInfo.processInfo.environment["networkDebug"] == "YES" {
                        print(String(data: data, encoding: .utf8) ?? "<no data>")
                    }
                }
                SwiftyBeaver.error(line)
                var message: JSONObject? = nil
                if let data = data, data.count > 0 {
                    message = try? JSONParser.JSONObjectGuaranteed(with: data)
                }
                let networkError = NetworkError.status(status: response.statusCode, message: message)
                self.finalizeNetworkCall(result: .error(networkError), headers: headers, completion: completion)
            }
        })
        task.resume()
    }

    func finalizeNetworkCall(result: Result<JSONObject>, headers: JSONObject?, completion: @escaping Network.ResponseCompletion) {
        DispatchQueue.main.async {
            completion(result, headers)
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
        } else if let objectValue = obj as? JSONObject {
            return objectValue
        } else {
            throw MarshalError.typeMismatch(expected: JSONObject.self, actual: type(of: obj))
        }
    }

}
