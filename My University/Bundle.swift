//
//  Bundle.swift
//  My University
//
//  Created by Yura Voevodin on 20.10.2019.
//  Copyright © 2019 Yura Voevodin. All rights reserved.
//

import Foundation

extension Bundle {
    
    /// Identifier of app main bundle
    static var identifier: String {
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            return bundleIdentifier
        } else {
            return "com.voevodin-yura.Schedule"
        }
    }
    
    /// Get the current bundle version for the app
    static var appVersion: String {
        let infoDictionaryKey = kCFBundleVersionKey as String
        guard let currentVersion = Bundle.main.object(forInfoDictionaryKey: infoDictionaryKey) as? String else { fatalError("Expected to find a bundle version in the info dictionary")
        }
        return currentVersion
    }
    
}
