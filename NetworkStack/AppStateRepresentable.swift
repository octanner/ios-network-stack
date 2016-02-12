//
//  AppStateRepresentable.swift
//  NetworkStack
//
//  Created by Ben Norris on 2/12/16.
//  Copyright © 2016 OC Tanner. All rights reserved.
//

import Foundation
import JaSON

public protocol AppStateRepresentable {
    var accessToken: String? { get }
    var loggedIn: Bool { get }
    var networkPath: String { get }
    func saveToken(json: JSONObject) throws
    func deleteToken()
}
