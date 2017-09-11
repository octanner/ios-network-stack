//
//  NSDate+ValueType.swift
//  NetworkStack
//
//  Created by Jason Larsen on 2/24/16.
//  Copyright © 2016 OC Tanner. All rights reserved.
//

import Foundation
import Marshal

extension Date: ValueType {
    
    public static func value(from object: Any) throws -> Date {
        // handle date strings
        if let dateString = object as? String {
            guard let date = Date.fromISO8601(string: dateString) else {
                throw MarshalError.typeMismatch(expected: "ISO8601 date string", actual: dateString)
            }
            return date
        }
            // handle NSDate objects
        else if let date = object as? Date {
            return date
        }
        else {
            throw MarshalError.typeMismatch(expected: String.self, actual: type(of: object))
        }
    }
}

public extension Date {
    
    static fileprivate let ISO8601MillisecondFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter
    }()
    
    static fileprivate let ISO8601SecondFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter
    }()
    
    static fileprivate let ISO8601YearMonthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    static fileprivate let formatters = [ISO8601MillisecondFormatter, ISO8601SecondFormatter, ISO8601YearMonthDayFormatter]
    
    static func fromISO8601(string: String) -> Date? {
        for formatter in formatters {
            if let date = formatter.date(from: string) {
                return date
            }
        }
        return .none
    }
}
