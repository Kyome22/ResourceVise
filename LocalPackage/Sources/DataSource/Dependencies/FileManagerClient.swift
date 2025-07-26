/*
 FileManagerClient.swift
 DataSource

 Created by Takuto Nakamura on 2024/11/17.
 
*/

import Foundation

public struct FileManagerClient: DependencyClient {
    public var attributesOfItem: @Sendable (String) throws -> [FileAttributeKey : Any]
    public var contentsOfDirectory: @Sendable (URL, [URLResourceKey]?) throws -> [URL]
    public var removeItem: @Sendable (URL) throws -> Void

    public static let liveValue = Self(
        attributesOfItem: { try FileManager.default.attributesOfItem(atPath: $0) },
        contentsOfDirectory: { try FileManager.default.contentsOfDirectory(at: $0, includingPropertiesForKeys: $1) },
        removeItem: { try FileManager.default.removeItem(at: $0) }
    )

    public static let testValue = Self(
        attributesOfItem: { _ in [:] },
        contentsOfDirectory: { _, _ in [] },
        removeItem: { _ in }
    )
}
