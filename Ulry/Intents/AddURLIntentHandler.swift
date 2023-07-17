//
//  AddURLIntentHandler.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/31/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import Intents

public enum AddURLIntentHandlerError: LocalizedError {
    case communicationFailure
    
    public var errorDescription: String? {
        switch self {
        case .communicationFailure:
            return NSLocalizedString("Unable to communicate with Ulry.", comment: "Communication failure")
        }
    }
}



public class AddURLIntentHandler: NSObject, AddURLIntentHandling {
    public func resolveUrl(for intent: AddURLIntent, with completion: @escaping (AddURLUrlResolutionResult) -> Void) {
        guard let url = intent.url else {
            completion(.unsupported(forReason: .required))
            return
        }
        completion(.success(with: url))
    }
    
    public func handle(intent: AddURLIntent, completion: @escaping (AddURLIntentResponse) -> Void) {
        let file = ExtensionsAddLinkRequestsManager()
        
        guard let urlString = intent.url, let _ = URL(string: urlString) else {
            completion(AddURLIntentResponse(code: .isNotValidUrl, userActivity: nil))
            return
        }

        guard file.canSaveMoreLinks else {
            completion(AddURLIntentResponse(code: .cannotSaveToExternalFile, userActivity: nil))
            return
        }

        file.add(urlString, note: nil)
        completion(AddURLIntentResponse(code: .success, userActivity: nil))
    }
    
}
