/*
 URLClient.swift
 DataSource

 Created by Takuto Nakamura on 2025/08/02.
 
*/

import Foundation

public struct URLClient: DependencyClient {
    var create: @Sendable (Data, URL.BookmarkResolutionOptions) throws -> (Bool, URL)
    var bookmarkData: @Sendable (URL, URL.BookmarkCreationOptions) throws -> Data
    var startAccessingSecurityScopedResource: @Sendable (URL) -> Bool
    var stopAccessingSecurityScopedResource: @Sendable (URL) -> Void

    public static let liveValue = Self(
        create: {
            var isStale = false
            let url = try URL(resolvingBookmarkData: $0, options: $1, bookmarkDataIsStale: &isStale)
            return (isStale, url)
        },
        bookmarkData: {
            try $0.bookmarkData(options: $1)
        },
        startAccessingSecurityScopedResource: {
            $0.startAccessingSecurityScopedResource()
        },
        stopAccessingSecurityScopedResource: {
            $0.stopAccessingSecurityScopedResource()
        }
    )

    public static let testValue = Self(
        create: { _, _ in throw URLError(.unknown) },
        bookmarkData: { _, _ in throw URLError(.unknown) },
        startAccessingSecurityScopedResource: { _ in false },
        stopAccessingSecurityScopedResource: { _ in }
    )
}
