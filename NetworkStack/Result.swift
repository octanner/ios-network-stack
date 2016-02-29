//
//  Result.swift
//  NetworkStack
//
//  Created by Jason Larsen on 2/23/16.
//  Copyright © 2016 OC Tanner. All rights reserved.
//

import Foundation

public enum Result<T> {
    case Ok(T)
    case Error(ErrorType)
    
    public func map<U>(@noescape f: T throws -> U) -> Result<U> {
        switch self {
        case let .Ok(x):
            do {
                return try .Ok(f(x))
            }
            catch {
                return .Error(error)
            }
        case let .Error(error):
            return .Error(error)
        }
    }
    
    public func flatMap<U>(@noescape f: T -> Result<U>) -> Result<U> {
        switch self {
        case let .Ok(x):
            return try f(x)
        case let .Error(error):
            return .Error(error)
        }
    }
}
