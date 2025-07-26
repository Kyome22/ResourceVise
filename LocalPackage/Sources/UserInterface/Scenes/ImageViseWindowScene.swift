/*
 WorkspaceWindow.swift
 UserInterface

 Created by Takuto Nakamura on 2024/11/13.
 
*/

import DataSource
import Model
import SwiftUI

public struct ImageViseWindowScene: Scene {
    @Environment(\.appDependencies) private var appDependencies
    @FocusedValue(\.imageViseSend) private var send
    @FocusedValue(\.disableToExport) private var disableToExport

    public init() {}

    public var body: some Scene {
        Window(Text("appTitle", bundle: .module), id: "imageVise") {
            ImageViseView(store: .init(appDependencies))
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .commands {
            CommandGroup(before: .newItem) {
                Button {
                    send?(.importButtonTapped)
                } label: {
                    Text("import", bundle: .module)
                }
                .keyboardShortcut("o", modifiers: .command)
                Button {
                    send?(.exportButtonTapped)
                } label: {
                    Text("convert", bundle: .module)
                }
                .keyboardShortcut("s", modifiers: .command)
                .disabled(disableToExport ?? true)
            }
        }
    }
}
