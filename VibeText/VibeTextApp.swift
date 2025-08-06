//
//  VibeTextApp.swift
//  VibeText
//
//  Created by Nick DeMarco on 7/29/25.
//

import SwiftUI

@main
struct VibeTextApp: App {
    
    init() {
        configureAPIProxy()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    // MARK: - Proxy Configuration
    
    private func configureAPIProxy() {
        // Store the VibeText auth token securely on first launch
        let authToken = "vt_prod_6d8eca254d3ed2b5112d795c633c16dda2fa48a81a8612258e7010c0"
        
        // Check if token is already stored
        if APIConfig.shared.getAuthToken() == nil {
            let success = APIConfig.shared.storeAuthToken(authToken)
            if success {
                print("✅ VibeText auth token stored successfully")
            } else {
                print("❌ Failed to store auth token")
            }
        } else {
            print("✅ VibeText auth token already exists in keychain")
        }
    }
}
