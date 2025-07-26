/*
 LoggingSystemClient.swift
 DataSource

 Created by Takuto Nakamura on 2024/11/13.
 
*/

import Logging

public struct LoggingSystemClient: DependencyClient {
    public var bootstrap: @Sendable (@escaping @Sendable (String) -> any LogHandler) -> Void

    public static let liveValue = Self(
        bootstrap: { LoggingSystem.bootstrap($0) }
    )

    public static let testValue = Self(
        bootstrap: { _ in }
    )
}
