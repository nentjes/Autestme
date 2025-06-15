//
//  NavigationViewWrapper.swift
//  Autestme1
//
//  Created by Markus Moritz on 14/06/2025.
//
import SwiftUI

struct NavigationViewWrapper: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            StartScreen(navigationPath: $path)
        }
    }
}
