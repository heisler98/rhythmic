//
//  IAPManager.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 9/19/20.
//  Copyright © 2020 Hunter Eisler. All rights reserved.
//

import StoreKit
import Combine

class IAPManager: NSObject, ObservableObject {
    private static var purchaseIDs = ["com.eisler.rhythmic.099tip", "com.eisler.rhythmic.199tip", "com.eisler.rhythmic.499tip", "com.eisler.rhythmic.999tip"]
    var products = Products()
    
    @Published var showNote: Bool = false
    
    override init() {
        super.init()
        verifyIDs()
    }
    
    func verifyIDs() {
        let request = SKProductsRequest(productIdentifiers: Set(IAPManager.purchaseIDs))
        request.delegate = self
        request.start()
    }
    
    func paymentsAllowed() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    func localizedPrice(of product: SKProduct) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        return formatter.string(from: product.price)
    }
    
    func startObserving() {
        SKPaymentQueue.default().add(self)
        restorePurchases()
    }
    
    func stopObserving() {
        SKPaymentQueue.default().remove(self)
    }
}

extension IAPManager: SKProductsRequestDelegate, SKRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        products.items = response.products
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        dLog(error)
    }
    
    func requestDidFinish(_ request: SKRequest) {
        dLog("Finished \(request)")
    }
}

extension IAPManager {
    final class Products: ObservableObject, Identifiable {
        var items: [SKProduct] = [] {
            willSet {
                DispatchQueue.main.sync {
                    objectWillChange.send()
                }
            }
        }
        
        
    }
}

extension IAPManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                showNote = true
                SKPaymentQueue.default().finishTransaction(transaction)
                break
            case .deferred, .purchasing:
                break
            case .failed:
                SKPaymentQueue.default().finishTransaction(transaction)
            default:
                break
            }
        }
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        // do nothing
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        // do nothing
    }
}

extension IAPManager {
    
    func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}
