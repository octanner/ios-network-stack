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
}
