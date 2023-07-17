//
//  AppData.swift
//  Ulry
//
//  Created by Mattia Righetti on 21/04/23.
//  Copyright © 2023 Mattia Righetti. All rights reserved.
//

import Foundation

struct AppData {
    /// String version of the app, i.e. `0.4.1`
    public static var appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
    /// Build version of the app, i.e. `64`
    public static var appBundleVersion: String = Bundle.main.infoDictionary?["CFBundleVersion"] as! String

    public static var userAgentSignature: String = "Ulry/\(appVersion)(\(appBundleVersion)"

    public static var supabaseApiKey: String {
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpnc295dmR2emRpd3lhdmN1dW9zIiwicm9sZSI6ImFub24iLCJpYXQiOjE2ODE5ODQ1NjAsImV4cCI6MTk5NzU2MDU2MH0.oeU3VqoeRrvsw6Oo5bb22hHqxJKa11tsiz6Sen_IcD8"
    }
}
