//
//  IAPManager.swift
//  Ulry
//
//  Created by Mattia Righetti on 3/2/22.
//

import Foundation
import StoreKit

final class IAPManager {
    static let shared = IAPManager()
    var task: Task<Void, Error>?
    
    init() {
        task = listenForStoreKitUpdates()
    }
    
    enum ProductsIdentifiers: String, CaseIterable {
        case coffee = "coffee_tip"
        case donut = "donut_tip"
        case pizza = "pizza_tip"
        case `super` = "super_tip"
        
        var value: String {
            return "com.mattrighetti.Ulry.iap" + "." + self.rawValue
        }
    }
    
    func fetchProducts() async throws -> [Product] {
        let products = try await Product.products(for: [
            ProductsIdentifiers.coffee.value,
            ProductsIdentifiers.donut.value,
            ProductsIdentifiers.pizza.value,
            ProductsIdentifiers.super.value
        ])
        
        return products
    }
    
    func purchase(_ product: Product) async throws -> Transaction {
        let result = try await product.purchase()
        
        switch result {
        case .pending:
            throw Product.PurchaseError.purchaseNotAllowed
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                await transaction.finish()
                return transaction
            case .unverified:
                throw Product.PurchaseError.invalidOfferSignature
            }
        case .userCancelled:
            throw Product.PurchaseError.purchaseNotAllowed
        @unknown default:
            assertionFailure("Unexpected result")
            throw Product.PurchaseError.purchaseNotAllowed
        }
    }
    
    func listenForStoreKitUpdates() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                switch result {
                case .verified(let transaction):
                    print("Transaction verified in listener")
                    await transaction.finish()
                case .unverified:
                    print("Transaction unverified")
                }
            }
        }
    }
}
