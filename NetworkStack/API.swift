//
//  API.swift
//  NetworkStack
//
//  Created by Benjamin Patch on 4/1/19.
//  Copyright © 2019 OC Tanner. All rights reserved.
//

import Foundation

/// A struct to hold the api endpoint string.
/// The suggested approach for defining API references is to extend the
/// sub-structs [Get](x-source-tag://APIGet), [Post](x-source-tag://APIPost), [Delete](x-source-tag://APIDelete)
/// [Patch](x-source-tag://APIPatch), [Put](x-source-tag://APIPut), and [HyperGet](x-source-tag://APIHyperGet)
/// and add the API references as `static let`s or `static func`s to each applicable
/// sub-struct.
public struct API: ExpressibleByStringLiteral {
    
    public var endpoint: String
    
    public init(_ endpoint: String) {
        self.endpoint = endpoint
    }
    
    // Expressible By String Literal Conformance
    /// This makes it so we can initialize an API object by simply assigning it to a String.
    /// i.e. var endpoint: API = "v1/endpoint/test"
    public init(stringLiteral: String) {
        self.endpoint = stringLiteral
    }
    
}


// MARK: Endpoint Container structs extension

public extension API {
    // These structs are meant to house the static let/func API's for the endpoints.
    // Endpoints are of type `API` and are represented as `static let` or `static func`

    /// This is a container struct for all endpoints that we Get to.
    /// Extend this struct to include the `static let` and `static func` endpoint `API`s
    /// - Tag: APIGet
    struct Get { }

    /// This is a container struct for all endpoints that we Get to.
    /// Extend this struct to include the `static let` and `static func` endpoint `API`s
    /// - Tag: APIPost
    struct Post { }

    /// This is a container struct for all endpoints that we Get to.
    /// Extend this struct to include the `static let` and `static func` endpoint `API`s
    /// - Tag: APIDelete
    struct Delete { }

    /// This is a container struct for all endpoints that we Get to.
    /// Extend this struct to include the `static let` and `static func` endpoint `API`s
    /// - Tag: APIPatch
    struct Patch { }

    /// This is a container struct for all endpoints that we Get to.
    /// Extend this struct to include the `static let` and `static func` endpoint `API`s
    /// - Tag: APIPut
    struct Put { }

    /// This is a container struct for all endpoints that we Get to.
    /// Extend this struct to include the `static let` and `static func` endpoint `API`s
    /// - Tag: APIHyperGet
    struct HyperGet { }
    
}

