import Foundation
import os
import Testing

@testable import DataSource
@testable import Model

@MainActor
struct HomePermissionTests {
    private let homeDirectory = URL(filePath: "/Users/test", directoryHint: .isDirectory)

    private func appStateClientWithHomeDirectory() -> AppStateClient {
        .testDependency(OSAllocatedUnfairLock(initialState: AppState(homeDirectory: homeDirectory)))
    }

    private func grantingURLClient(startedURLs: OSAllocatedUnfairLock<[URL]>) -> URLClient {
        testDependency(of: URLClient.self) {
            $0.startAccessingSecurityScopedResource = { url in
                startedURLs.withLock { $0.append(url) }
                return true
            }
            $0.bookmarkData = { _, _ in Data([1, 2, 3]) }
        }
    }

    private func storingUserDefaultsClient(stored: OSAllocatedUnfairLock<Data?>) -> UserDefaultsClient {
        testDependency(of: UserDefaultsClient.self) {
            $0.object = { _ in stored.withLock(\.self).map { $0 as Any } }
            $0.data = { _ in stored.withLock(\.self) }
            $0.setData = { data, _ in stored.withLock { $0 = data } }
            $0.removeObject = { _ in stored.withLock { $0 = nil } }
        }
    }

    @Test
    func send_viewAppeared_bookmarkStateIsRestored() async {
        let stored = OSAllocatedUnfairLock<Data?>(initialState: Data([1, 2, 3]))
        let store = HomePermission(
            .testDependencies(userDefaultsClient: storingUserDefaultsClient(stored: stored)),
            bookmarkState: .notSaved
        )
        await store.send(.viewAppeared("HomePermissionView"))
        #expect(store.bookmarkState == .saved)
    }

    @Test
    func send_grantPermissionButtonTapped_fileImporterIsPresented() async {
        let store = HomePermission(.testDependencies())
        await store.send(.grantPermissionButtonTapped)
        #expect(store.isPresentedFileImporter)
    }

    @Test
    func send_grantPermissionCompleted_homeDirectoryIsSelected_bookmarkIsStored() async {
        let stored = OSAllocatedUnfairLock<Data?>(initialState: nil)
        let startedURLs = OSAllocatedUnfairLock<[URL]>(initialState: [])
        let store = HomePermission(.testDependencies(
            appStateClient: appStateClientWithHomeDirectory(),
            urlClient: grantingURLClient(startedURLs: startedURLs),
            userDefaultsClient: storingUserDefaultsClient(stored: stored)
        ))
        await store.send(.grantPermissionCompleted(.success(homeDirectory)))
        #expect(stored.withLock(\.self) == Data([1, 2, 3]))
        #expect(store.bookmarkState == .saved)
    }

    @Test
    func send_grantPermissionCompleted_otherDirectoryIsSelected_bookmarkIsNotStored() async {
        let stored = OSAllocatedUnfairLock<Data?>(initialState: nil)
        let startedURLs = OSAllocatedUnfairLock<[URL]>(initialState: [])
        let store = HomePermission(.testDependencies(
            appStateClient: appStateClientWithHomeDirectory(),
            urlClient: grantingURLClient(startedURLs: startedURLs),
            userDefaultsClient: storingUserDefaultsClient(stored: stored)
        ))
        await store.send(.grantPermissionCompleted(
            .success(URL(filePath: "/Users/test/Documents", directoryHint: .isDirectory))
        ))
        #expect(stored.withLock(\.self) == nil)
        #expect(store.bookmarkState == .notSaved)
    }

    @Test
    func send_grantPermissionCompleted_failure_bookmarkIsNotStored() async {
        let stored = OSAllocatedUnfairLock<Data?>(initialState: nil)
        let startedURLs = OSAllocatedUnfairLock<[URL]>(initialState: [])
        let store = HomePermission(.testDependencies(
            appStateClient: appStateClientWithHomeDirectory(),
            urlClient: grantingURLClient(startedURLs: startedURLs),
            userDefaultsClient: storingUserDefaultsClient(stored: stored)
        ))
        await store.send(.grantPermissionCompleted(.failure(URLError(.unknown))))
        #expect(stored.withLock(\.self) == nil)
        #expect(store.bookmarkState == .notSaved)
    }

    @Test
    func send_setUpLaterButtonTapped_parentIsNotified() async {
        let isNotified = OSAllocatedUnfairLock<Bool>(initialState: false)
        let store = HomePermission(.testDependencies(), action: { action in
            if case .setUpLaterButtonTapped = action {
                isNotified.withLock { $0 = true }
            }
        })
        await store.send(.setUpLaterButtonTapped)
        #expect(isNotified.withLock(\.self) == true)
    }

    @Test
    func send_revokePermissionButtonTapped_bookmarkIsRemoved() async {
        let stored = OSAllocatedUnfairLock<Data?>(initialState: Data([1, 2, 3]))
        let store = HomePermission(
            .testDependencies(userDefaultsClient: storingUserDefaultsClient(stored: stored)),
            bookmarkState: .saved
        )
        await store.send(.revokePermissionButtonTapped)
        #expect(stored.withLock(\.self) == nil)
        #expect(store.bookmarkState == .notSaved)
    }

    @Test
    func send_closeButtonTapped_parentIsNotified() async {
        let isNotified = OSAllocatedUnfairLock<Bool>(initialState: false)
        let store = HomePermission(.testDependencies(), action: { action in
            if case .closeButtonTapped = action {
                isNotified.withLock { $0 = true }
            }
        })
        await store.send(.closeButtonTapped)
        #expect(isNotified.withLock(\.self) == true)
    }
}
