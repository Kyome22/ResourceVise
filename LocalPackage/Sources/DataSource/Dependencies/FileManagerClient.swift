/*
 FileManagerClient.swift
 DataSource

 Created by Takuto Nakamura on 2024/11/17.
 
*/

import Foundation

public struct FileManagerClient: DependencyClient {
    public var homeDirectoryForCurrentUser: @Sendable () -> URL
    public var attributesOfItem: @Sendable (String) throws -> [FileAttributeKey : Any]
    public var fileExists: @Sendable (String) -> Bool
    public var removeItem: @Sendable (URL) throws -> Void
    public var isDirectory: @Sendable (URL) -> Bool
    public var contentsOfDirectory: @Sendable (URL) throws -> [URL]

    public static let liveValue = Self(
        homeDirectoryForCurrentUser: { FileManager.default.homeDirectoryForCurrentUser },
        attributesOfItem: { try FileManager.default.attributesOfItem(atPath: $0) },
        fileExists: { FileManager.default.fileExists(atPath: $0) },
        removeItem: { try FileManager.default.removeItem(at: $0) },
        isDirectory: { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false },
        contentsOfDirectory: {
            try FileManager.default.contentsOfDirectory(
                at: $0,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
            )
        }
    )

    public static let testValue = Self(
        homeDirectoryForCurrentUser: { URL(filePath: "/Users/test", directoryHint: .isDirectory) },
        attributesOfItem: { _ in [:] },
        fileExists: { _ in false },
        removeItem: { _ in },
        isDirectory: { _ in false },
        contentsOfDirectory: { _ in [] }
    )
}
