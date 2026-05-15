/*
 AppDependencies.swift
 Model

 Created by Takuto Nakamura on 2024/11/13.
 
*/

import DataSource
import SwiftUI

public struct AppDependencies: Sendable {
    public var appStateClient = AppStateClient.liveValue
    public var dataClient = DataClient.liveValue
    public var fileManagerClient = FileManagerClient.liveValue
    public var loggingSystemClient = LoggingSystemClient.liveValue
    public var nsImageClient = NSImageClient.liveValue
    public var nsWorkspaceClient = NSWorkspaceClient.liveValue
    public var urlClient = URLClient.liveValue
    public var userDefaultsClient = UserDefaultsClient.liveValue

    static let shared = AppDependencies()
}

public extension EnvironmentValues {
    @Entry var appDependencies = AppDependencies.shared
}

extension AppDependencies {
    public static func testDependencies(
        appStateClient: AppStateClient = .testValue,
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
