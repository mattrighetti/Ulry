//
//  URLManager.swift
//  Urly
//
//  Created by Mattia Righetti on 1/1/22.
//

import Foundation
import os

class URLManager: ObservableObject {
    public static var shared = URLManager()
    
    public func getURLData(url urlString: String, completion handler: (([String:String]) -> Void)? = nil) {
        DispatchQueue.global().async {
            do {
                let result = try MetaRod().build(urlString).og()
                handler?(result)
            } catch {
                os_log(.error, "encountered error while fetching URL data")
            }
        }
    }
}
