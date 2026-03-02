//
//  ContentView.swift
//  smakofon
//
//  Root view – TabView with Camera and Vehicle Journal.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            CameraScreen()
                .tabItem {
                    Label("Scanner", systemImage: "camera.viewfinder")
                }

            HistoryScreen()
                .tabItem {
                    Label("Journal", systemImage: "list.clipboard")
                }
        }
        .tint(.green)
    }
}

#Preview {
    ContentView()
}
