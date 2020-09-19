//
//  InfoView.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 9/18/20.
//  Copyright © 2020 Hunter Eisler. All rights reserved.
//

import SwiftUI
import StoreKit

struct InfoView: View {
    @EnvironmentObject var purchaseManager: IAPManager
    var body: some View {
        NavigationView {
            VStack {
                if purchaseManager.paymentsAllowed() {
                    TipJarView()
                        .padding(.bottom, 25)
                }
                Divider()
                List {
                    NavigationLink(destination: ScrollView {
                        Text(Licensing.essentiaLicense)
                            .multilineTextAlignment(.leading)
                            .font(.callout)
                            .padding(5)
                            .navigationBarTitle("Licenses")
                    }) {
                        Text("Licenses")
                    }
                }
            }.navigationBarHidden(true)
        }
    }
}

struct TipJarView: View {
    @EnvironmentObject var purchaseManager: IAPManager
    @EnvironmentObject var productManager: IAPManager.Products
    var body: some View {
        VStack {
            Text("Tip Jar")
                .font(.headline)
                .padding(.top)
            Text("Leave a tip for the developer. Completely optional.")
                .font(.caption)
                .padding(.top, 2)
                .padding(.bottom, 5)
            HStack(spacing: 30) {
                Button {
                    startPurchasing(productManager.items[0])
                } label: {
                    Text("$0.99")
                        .modifier(TipModifier())
                }
                Button {
                    startPurchasing(productManager.items[1])
                } label: {
                    Text("$1.99")
                        .modifier(TipModifier())
                }
                Button {
                    startPurchasing(productManager.items[2])
                } label: {
                    Text("$4.99")
                        .modifier(TipModifier())
                }
                Button {
                    startPurchasing(productManager.items[3])
                } label: {
                    Text("$9.99")
                        .modifier(TipModifier())
                }
            }
        }
    }
    
    func startPurchasing(_ product: SKProduct) {
        guard purchaseManager.paymentsAllowed() else { return }
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    struct TipModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .padding()
                .layoutPriority(1)
                .background(RoundedRectangle(cornerRadius: 15).fill(Color.green).opacity(0.6).shadow(radius: 10))
        }
    }
}

fileprivate struct Licensing {
    static var essentiaLicense: String {
        let essentiaLicense = Bundle.main.path(forResource: "Essentia Licensing", ofType: "txt")
        guard let license = try? String(contentsOfFile: essentiaLicense ?? "") else {
            return ""
        }
        return license
    }
}
