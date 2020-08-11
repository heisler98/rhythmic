//
//  ContentView.swift
//  Shared
//
//  Created by Hunter Eisler on 8/6/20.
//

import SwiftUI

struct ExperimentalView: View {
    @State private var largeTitle: Bool = false
    @StateObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            controlView
                .padding(.vertical)
                .padding(.bottom, 10)
                .animation(.easeInOut)
            RoundedRectangle(cornerRadius: 35)
                .fill(Color.white)
                .shadow(radius: 10)
                .padding(.horizontal, 5)
                .overlay(
                    List {
                        Section(header: Text("Library")) {
                        ForEach(0..<20) { _ in
                            Text("Let's Hurt Tonight")
                                .fontWeight(.light)
                        }
                        }
                    }.modifier(ListModifier())
                )
            
            
        }
    }
    
    var controlView: some View {
        VStack(alignment: .center, spacing: 15) {
            Text("Let's Hurt Tonight")
                .font((largeTitle) ? .title : .caption)
                .fontWeight(.bold)
            
            Slider(value: .constant(0.5), in: 0...1)
                .accentColor(.gray)
                .padding(.horizontal)
            
            HStack(alignment: .center, spacing: 50) {
                Button(action: {}) {
                    Image(systemName: "backward.fill")
                        .resizable()
                        .scaledToFit()
                }.frame(maxWidth: 44)
                
                Button(action: {}) {
                    Image(systemName: "pause.fill")
                        .resizable()
                        .scaledToFit()
                }.frame(maxWidth: 34)
                Button(action: {}) {
                    Image(systemName: "forward.fill")
                        .resizable()
                        .scaledToFit()
                }.frame(maxWidth: 44)
            }
        }
    }
}

struct ExperimentalView_Previews: PreviewProvider {
    static var previews: some View {
        ExperimentalView(appState: AppState())
    }
}

import Combine
class AppState: ObservableObject {
    
}

struct ListModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 14.0, *) {
            return AnyView(content.listStyle(InsetGroupedListStyle()))
        } else {
            return AnyView(content.listStyle(DefaultListStyle()))
        }
    }
}
