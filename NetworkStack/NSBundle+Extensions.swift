//
//  NSBundle+Extensions.swift
//  NetworkStack
//
//  Created by Tim on 10/28/16.
//  Copyright © 2016 OC Tanner. All rights reserved.
//

import Foundation


extension NSBundle {

    var acceptLanguages: String {
        return preferredLocalizations.enumerate().map { index, language in
            return index == 0 ? language : "\(language);q=\(1.0 - Float(index)/10.0)"
        }.joinWithSeparator(", ")
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
