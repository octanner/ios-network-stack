//
//  NSDate+ValueType.swift
//  NetworkStack
//
//  Created by Jason Larsen on 2/24/16.
//  Copyright © 2016 OC Tanner. All rights reserved.
//

import Foundation
import Marshal

extension NSDate: ValueType {
    
    public static func value(object: Any) throws -> NSDate {
        // handle date strings
        if let dateString = object as? String {
            guard let date = NSDate.fromISO8601String(dateString) else {
                throw Marshal.Error.TypeMismatch(expected: "ISO8601 date string", actual: dateString)
            }
            return date
        }
            // handle NSDate objects
        else if let date = object as? NSDate {
            return date
        }
        else {
            throw Marshal.Error.TypeMismatch(expected: String.self, actual: object.dynamicType)
        }
    }
}

public extension NSDate {
    
    static private let ISO8601MillisecondFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let tz = NSTimeZone(abbreviation:"GMT")
        formatter.timeZone = tz
        return formatter
    }()
    
    static private let ISO8601SecondFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let tz = NSTimeZone(abbreviation:"GMT")
        formatter.timeZone = tz
        return formatter
    }()
    
    static private let ISO8601YearMonthDayFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    static private let formatters = [ISO8601MillisecondFormatter, ISO8601SecondFormatter, ISO8601YearMonthDayFormatter]
    
    static func fromISO8601String(dateString:String) -> NSDate? {
        for formatter in formatters {
            if let date = formatter.dateFromString(dateString) {
                return date
            }
        }
        return .None
    }
}