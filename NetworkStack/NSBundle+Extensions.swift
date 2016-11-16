//
//  NSBundle+Extensions.swift
//  NetworkStack
//
//  Created by Tim on 10/28/16.
//  Copyright © 2016 OC Tanner. All rights reserved.
//

import Foundation


extension Bundle {

    var acceptLanguages: String {
        return Locale.preferredLanguages.enumerated().map { index, locale in
            let language = locale.components(separatedBy: "-").first!
            let priority = 1.0 - Float(index)/10.0
            return "\(locale);q=\(priority),\(language);q=\(priority - 0.05)"
            }.joined(separator: ",")
    }

    var identifier: String {
        return bundleIdentifier ?? "unknown_app"
    }

    var buildVersion: String {
        return (infoDictionary?["CFBundleVersion"] as? String) ?? "unknown_version"
    }

    var identifierBuildVersion: String {
        return "\(identifier)-\(buildVersion)"
    }

}
