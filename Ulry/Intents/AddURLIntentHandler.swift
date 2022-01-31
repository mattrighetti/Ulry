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
        guard let url = intent.url else {
            completion(AddURLIntentResponse(code: .failure, userActivity: nil))
            return
        }
        
        let link = Link()
        link.url = url.absoluteString
        link.group = nil
        link.tags = nil
        
        let dataFetcher = DataFetcher()
        
        dataFetcher.fetchData(for: link, completion: {
            CoreDataStack.shared.saveContext()
            completion(AddURLIntentResponse(code: .success, userActivity: nil))
        })
        
        DispatchQueue.main.asyncAfter(wallDeadline: .now() + 10.0) {
            completion(AddURLIntentResponse(code: .failure, userActivity: nil))
        }
    }
    
}
