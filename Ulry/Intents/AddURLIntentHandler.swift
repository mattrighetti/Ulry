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
        guard let validated = SharedWebURL.parse(url) else {
            completion(.unsupported())
            return
        }
        completion(.success(with: validated.absoluteString))
    }
    
    public func handle(intent: AddURLIntent, completion: @escaping (AddURLIntentResponse) -> Void) {
        let file = ExtensionsAddLinkRequestsManager()
        
        guard let urlString = intent.url else {
            completion(AddURLIntentResponse(code: .isNotValidUrl, userActivity: nil))
            return
        }
        let code: AddURLIntentResponseCode
        switch file.save(urlString, note: nil) {
        case .saved: code = .success
        case .invalidURL: code = .isNotValidUrl
        case .full, .storageFailure: code = .cannotSaveToExternalFile
        }
        completion(AddURLIntentResponse(code: code, userActivity: nil))
    }
    
}
