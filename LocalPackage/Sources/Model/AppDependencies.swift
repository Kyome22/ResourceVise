/*
 AppDependencies.swift
 Model

 Created by Takuto Nakamura on 2024/11/13.

*/

import DataSource
import SwiftUI

public final class AppDependencies: Sendable {
    public let appStateClient: AppStateClient
    public let cgImageSourceClient: CGImageSourceClient
    public let dataClient: DataClient
    public let fileManagerClient: FileManagerClient
    public let loggingSystemClient: LoggingSystemClient
    public let nsImageClient: NSImageClient
    public let nsWorkspaceClient: NSWorkspaceClient
    public let urlClient: URLClient
    public let userDefaultsClient: UserDefaultsClient

    nonisolated init(
        appStateClient: AppStateClient = .liveValue,
        cgImageSourceClient: CGImageSourceClient = .liveValue,
        dataClient: DataClient = .liveValue,
        fileManagerClient: FileManagerClient = .liveValue,
        loggingSystemClient: LoggingSystemClient = .liveValue,
        nsImageClient: NSImageClient = .liveValue,
        nsWorkspaceClient: NSWorkspaceClient = .liveValue,
        urlClient: URLClient = .liveValue,
        userDefaultsClient: UserDefaultsClient = .liveValue
    ) {
        self.appStateClient = appStateClient
        self.cgImageSourceClient = cgImageSourceClient
        self.dataClient = dataClient
        self.fileManagerClient = fileManagerClient
        self.loggingSystemClient = loggingSystemClient
        self.nsImageClient = nsImageClient
        self.nsWorkspaceClient = nsWorkspaceClient
        self.urlClient = urlClient
        self.userDefaultsClient = userDefaultsClient
    }

    static let shared = AppDependencies()
}

extension EnvironmentValues {
    @Entry public var appDependencies = AppDependencies.shared
}

extension AppDependencies {
    public static func testDependencies(
        appStateClient: AppStateClient = .testValue,
        cgImageSourceClient: CGImageSourceClient = .testValue,
        dataClient: DataClient = .testValue,
        fileManagerClient: FileManagerClient = .testValue,
        loggingSystemClient: LoggingSystemClient = .testValue,
        nsImageClient: NSImageClient = .testValue,
        nsWorkspaceClient: NSWorkspaceClient = .testValue,
        urlClient: URLClient = .testValue,
        userDefaultsClient: UserDefaultsClient = .testValue
    ) -> AppDependencies {
        AppDependencies(
            appStateClient: appStateClient,
            cgImageSourceClient: cgImageSourceClient,
            dataClient: dataClient,
            fileManagerClient: fileManagerClient,
            loggingSystemClient: loggingSystemClient,
            nsImageClient: nsImageClient,
            nsWorkspaceClient: nsWorkspaceClient,
            urlClient: urlClient,
            userDefaultsClient: userDefaultsClient
        )
    }
}
