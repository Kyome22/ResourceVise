/*
 NSWorkspaceClient.swift
 DataSource

 Created by Takuto Nakamura on 2024/11/18.
 
*/

import AppKit

public struct NSWorkspaceClient: DependencyClient {
    public var urlForApplication: @Sendable (String) -> URL?
    public var open: @Sendable ([URL], URL) -> Void

    public static let liveValue = Self(
        urlForApplication: { NSWorkspace.shared.urlForApplication(withBundleIdentifier: $0) },
        open: { NSWorkspace.shared.open($0, withApplicationAt: $1, configuration: .init()) }
    )

    public static let testValue = Self(
        urlForApplication: { _ in nil },
        open: { _, _ in }
    )
}
