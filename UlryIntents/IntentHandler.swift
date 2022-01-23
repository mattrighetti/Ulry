//
//  IntentHandler.swift
//  UlryIntents
//
//  Created by Mattia Righetti on 1/18/22.
//

import Intents
import Ulry

// As an example, this class is set up to handle Message intents.
// You will want to replace this or add other intents as appropriate.
// The intents you wish to handle must be declared in the extension's Info.plist.

class UrlIntentHandler: INExtension, AddURLIntentHandling  {
    func provideUrlOptionsCollection(for intent: AddURLIntent, searchTerm: String?, with completion: @escaping (INObjectCollection<NSURL>?, Error?) -> Void) {
        return
    }
    
    func handle(intent: AddURLIntent) async -> AddURLIntentResponse {
        guard let url = intent.url else {
            return AddURLIntentResponse(code: .failure, userActivity: nil)
        }
        
        let link = Link()
        link.url = url.absoluteString
        link.group = nil
        link.tags = nil
        
        return AddURLIntentResponse(code: .success, userActivity: NSUserActivity(activityType: "Activity type"))
    }
    
    
}

class UrlsIntentHandler: INExtension, AddURLsIntentHandling {
    func provideUrlsOptionsCollection(for intent: AddURLsIntent, searchTerm: String?, with completion: @escaping (INObjectCollection<NSString>?, Error?) -> Void) {
        return
    }
    
    func handle(intent: AddURLsIntent) async -> AddURLsIntentResponse {
        guard let urls = intent.urls else {
            return AddURLsIntentResponse(code: .failure, userActivity: nil)
        }
        
        for url in urls {
            let link = Link()
            link.url = url
            link.group = nil
            link.tags = nil
        }
        
        return AddURLsIntentResponse(code: .success, userActivity: NSUserActivity(activityType: "Activity type"))
    }
}
