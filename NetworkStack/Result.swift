//
//  Result.swift
//  NetworkStack
//
//  Created by Jason Larsen on 2/23/16.
//  Copyright © 2016 OC Tanner. All rights reserved.
//

import Foundation

public enum Result<T> {
    case ok(T)
    case error(Error)
    
    public func map<U>(_ f: (T) throws -> U) -> Result<U> {
        switch self {
        case let .ok(x):
            do {
                return try .ok(f(x))
            }
            catch {
                return .error(error)
            }
        case let .error(error):
            return .error(error)
        }
    }
    
    public func flatMap<U>(_ f: (T) -> Result<U>) -> Result<U> {
        switch self {
        case let .ok(x):
            return f(x)
        case let .error(error):
            return .error(error)
        }
    }
}
