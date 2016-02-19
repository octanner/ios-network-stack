//
//  Resource.swift
//  NetworkStack
//
//  Created by Jason Larsen on 2/19/16.
//  Copyright © 2016 OC Tanner. All rights reserved.
//

import Foundation
import JaSON

public struct Resource<ResponseObject: JSONObjectConvertible> {
    public var method: HTTPMethod
    public var path: String
    public var requestBody: NSData?
    public var headers: [String: String]
    public var parameters: [String: String]
    
    public init(method: HTTPMethod, path: String, requestBody: NSData? = nil, headers: [String: String] = [String: String](), parameters: [String: String] = [String: String]()) {
        self.method = method
        self.path = path
        self.requestBody = requestBody
        self.headers = headers
        self.parameters = parameters
    }
}