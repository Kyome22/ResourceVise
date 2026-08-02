/*
 AppState.swift
 DataSource

 Created by Takuto Nakamura on 2025/07/27.

*/

import Foundation

public struct AppState: Sendable {
    public var hasAlreadyBootstrap: Bool
    public var homeDirectory: URL?
    public var progress = AsyncStreamBundle<Double>()

    init(
        hasAlreadyBootstrap: Bool = false,
        homeDirectory: URL? = nil
    ) {
        self.hasAlreadyBootstrap = hasAlreadyBootstrap
        self.homeDirectory = homeDirectory
    }
}
