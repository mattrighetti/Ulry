//
//  AddURLIntentHandler.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/31/22.
//

import Intents

public enum AddURLIntentHandlerError: LocalizedError {
    case communicationFailure
    
    public var errorDescription: String? {
        switch self {
        case .communicationFailure:
            return NSLocalizedString("Unable to communicate with NetNewsWire.", comment: "Communication failure")
        }
    }
}



public class AddURLIntentHandler: NSObject, AddURLIntentHandling {
    
    override init() {
        super.init()
    }
    
    public func resolveUrl(for intent: AddURLIntent, with completion: @escaping (AddURLUrlResolutionResult) -> Void) {
        guard let url = intent.url else {
            completion(.unsupported(forReason: .required))
            return
        }
        completion(.success(with: url))
    }
    
    public func handle(intent: AddURLIntent, completion: @escaping (AddURLIntentResponse) -> Void) {
        let database = Database.external
        
        guard let urlString = intent.url else {
            completion(AddURLIntentResponse(code: .failure, userActivity: nil))
            return
        }
        
        let link = Link(url: urlString)
        let ok = database.insert(link)
        
        DispatchQueue.main.async {
            completion(AddURLIntentResponse(code: ok ? .success : .failure, userActivity: nil))
        }
    }
    
}
