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
    @State private var showingLicense: Bool = true
    var body: some View {
        NavigationView {
            VStack {
                if purchaseManager.paymentsAllowed() {
                    TipJarView()
                        .padding(.bottom, 25)
                }
                Divider()
                List {
                    DisclosureGroup("Licenses", isExpanded: $showingLicense) {
                        Text(Licensing.essentiaLicense)
                    }
                }
            }
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
            Text("Tip Caption")
                .font(.caption)
                .padding(.top, 2)
                .padding(.bottom, 5)
            HStack(spacing: 30) {
                Button {
                    startPurchasing(productManager.items[0])
                } label: {
                    Text("\(purchaseManager.localizedPrice(of: productManager.items[0]) ?? "")")
                        .modifier(TipModifier())
                }
                Button {
                    startPurchasing(productManager.items[1])
                } label: {
                    Text("\(purchaseManager.localizedPrice(of: productManager.items[1]) ?? "")")
                        .modifier(TipModifier())
                }
                Button {
                    startPurchasing(productManager.items[2])
                } label: {
                    Text("\(purchaseManager.localizedPrice(of: productManager.items[2]) ?? "")")
                        .modifier(TipModifier())
                }
                Button {
                    startPurchasing(productManager.items[3])
                } label: {
                    Text("\(purchaseManager.localizedPrice(of: productManager.items[3]) ?? "")")
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
    static var model: [LicensingLayout] = [LicensingLayout("Licenses", child: LicensingLayout(LocalizedStringKey(essentiaLicense), child: nil))]
    
    struct LicensingLayout: Identifiable {
        var id: UUID = UUID()
        var title: [LocalizedStringKey]
        var child: [LicensingLayout]?
        init(_ title: LocalizedStringKey, child: LicensingLayout?) {
            self.title = [title]
            self.child = (child == nil) ? nil : [child!]
        }
    }
}
