//
//  IntentHandler.swift
//  UlryIntents
//
//  Created by Mattia Righetti on 1/18/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import Intents

// As an example, this class is set up to handle Message intents.
// You will want to replace this or add other intents as appropriate.
// The intents you wish to handle must be declared in the extension's Info.plist.

class IntentHandler: INExtension {
    override func handler(for intent: INIntent) -> Any? {
        switch intent {
        case is AddURLIntent:
            return AddURLIntentHandler()
        default:
            fatalError("Unhandled intent type: \(intent)")
        }
        
    }
}
