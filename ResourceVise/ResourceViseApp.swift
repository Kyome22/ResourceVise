//
//  ResourceViseApp.swift
//  ResourceVise
//
//  Created by Takuto Nakamura on 2024/11/13.
//

import Model
import UserInterface
import SwiftUI

@main
struct ResourceViseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        ImageViseWindowScene()
    }
}
