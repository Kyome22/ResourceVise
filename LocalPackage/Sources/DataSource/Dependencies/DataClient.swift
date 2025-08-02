/*
 DataClient.swift
 DataSource

 Created by Takuto Nakamura on 2025/08/02.
 
*/

import Foundation

public struct DataClient: DependencyClient {
    public var write: @Sendable (Data, URL) throws -> Void

    public static let liveValue = Self(
        write: { try $0.write(to: $1)  }
    )

    public static let testValue = Self(
        write: { _, _ in }
    )
}
