/*
 AppDependencies.swift
 Model

 Created by Takuto Nakamura on 2024/11/13.
 
*/

import DataSource
import SwiftUI

public final class AppDependencies: Sendable {
    public let appStateClient: AppStateClient
    public let fileManagerClient: FileManagerClient
    public let loggingSystemClient: LoggingSystemClient
    public let nsWorkspaceClient: NSWorkspaceClient

    public nonisolated init(
        appStateClient: AppStateClient = .liveValue,
        fileManagerClient: FileManagerClient = .liveValue,
        loggingSystemClient: LoggingSystemClient = .liveValue,
        nsWorkspaceClient: NSWorkspaceClient = .liveValue
    ) {
        self.appStateClient = appStateClient
        self.fileManagerClient = fileManagerClient
        self.loggingSystemClient = loggingSystemClient
        self.nsWorkspaceClient = nsWorkspaceClient
    }

    static let shared = AppDependencies()
}

public extension EnvironmentValues {
    @Entry var appDependencies = AppDependencies.shared
}

extension AppDependencies {
    public static func testDependencies(
        appStateClient: AppStateClient = .testValue,
        fileManagerClient: FileManagerClient = .testValue,
        loggingSystemClient: LoggingSystemClient = .testValue,
        nsWorkspaceClient: NSWorkspaceClient = .testValue
    ) -> AppDependencies {
        AppDependencies(
            appStateClient: appStateClient,
            fileManagerClient: fileManagerClient,
            loggingSystemClient: loggingSystemClient,
            nsWorkspaceClient: nsWorkspaceClient
        )
    }
}
