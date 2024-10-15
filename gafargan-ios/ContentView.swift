//
//  ContentView.swift
//  gafargan-ios
//
//  Created by Kamran Tadzjibov on 14/10/2024.
//

import SwiftUI

struct ContentView: View {
    @State private var isLoading = true
    
    var body: some View {
        WebView(
            url: Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "dist")!,
            isLoading: $isLoading
        )
        .overlay {
            if isLoading {
                ZStack {
                    Color.white.opacity(0.8)
                        .edgesIgnoringSafeArea(.all)
                    VStack {
                        Spacer()
                        HStack {
                            ProgressView()
                            Text("Ппарзава")
                                .font(.headline)
                                .padding(.leading, 10)
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
//        .ignoresSafeArea()
        
    }
}

//#Preview {
//    ContentView()
//}
