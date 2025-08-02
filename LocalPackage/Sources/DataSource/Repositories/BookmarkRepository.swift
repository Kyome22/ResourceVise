/*
 BookmarkRepository.swift
 DataSource

 Created by Takuto Nakamura on 2025/08/02.
 
*/

import Foundation

public struct BookmarkRepository: Sendable {
    private let urlClient: URLClient
    private let userDefaultsClient: UserDefaultsClient

    private var bookmark: URL? {
        guard let bookmarkData = userDefaultsClient.data(.boomarkData),
              let (isStale, url) = try? urlClient.create(bookmarkData, .withSecurityScope),
              !isStale else {
            userDefaultsClient.removeObject(.boomarkData)
            return nil
        }
        return url
    }

    public var bookmarkState: BookmarkState {
        switch userDefaultsClient.object(.boomarkData) {
        case .some: .saved
        case .none: .notSaved
        }
    }

    public init(
        _ urlClient: URLClient,
        _ userDefaultsClient: UserDefaultsClient
    ) {
        self.urlClient = urlClient
        self.userDefaultsClient = userDefaultsClient
    }

    public func set(_ url: URL) throws {
        if urlClient.startAccessingSecurityScopedResource(url) {
            let bookmarkData = try urlClient.bookmarkData(url, .withSecurityScope)
            userDefaultsClient.setData(bookmarkData, .boomarkData)
            urlClient.stopAccessingSecurityScopedResource(url)
        }
    }

    public func enable() -> Bool {
        if let bookmark {
            urlClient.startAccessingSecurityScopedResource(bookmark)
        } else {
            false
        }
    }

    public func disable() {
        if let bookmark {
            urlClient.stopAccessingSecurityScopedResource(bookmark)
        }
    }

    public func remove() {
        disable()
        userDefaultsClient.removeObject(.boomarkData)
    }
}
