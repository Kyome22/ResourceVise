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
    @FocusedValue(\.disableToConvert) private var disableToConvert

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
                    Task {
                        await send?(.importButtonTapped)
                    }
                } label: {
                    Text("import", bundle: .module)
                }
                .keyboardShortcut("o", modifiers: .command)
                Button {
                    Task {
                        await send?(.convertButtonTapped)
                    }
                } label: {
                    Text("convert", bundle: .module)
                }
                .keyboardShortcut("s", modifiers: .command)
                .disabled(disableToConvert ?? true)
            }
        }
    }
}
