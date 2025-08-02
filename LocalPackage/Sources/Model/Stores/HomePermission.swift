/*
 HomePermission.swift
 Model

 Created by Takuto Nakamura on 2025/08/02.
 
*/

import DataSource
import Foundation
import Observation

@MainActor @Observable public final class HomePermission: Identifiable {
    private let appStateClient: AppStateClient
    private let bookmarkRepository: BookmarkRepository
    private let logService: LogService
    private let action: @MainActor (Action) async -> Void

    public let id: UUID
    public var bookmarkState: BookmarkState
    public var isPresentedFileImporter: Bool
    public var homeDirectory: URL? {
        appStateClient.withLock(\.homeDirectory)
    }
    public var homeDirectoryPath: String {
        homeDirectory?.path() ?? "/Users/UserName/"
    }
    public var predicate: Predicate<URL> {
        let home = homeDirectory
        return #Predicate<URL> { value in
            if let home {
                value.hasDirectoryPath && value == home
            } else {
                false
            }
        }
    }

    public init(
        _ appDependencies: AppDependencies,
        id: UUID = UUID(),
        bookmarkState: BookmarkState = .notSaved,
        isPresentedFileImporter: Bool = false,
        action: @MainActor @escaping (Action) async -> Void
    ) {
        self.appStateClient = appDependencies.appStateClient
        self.bookmarkRepository = .init(appDependencies.urlClient, appDependencies.userDefaultsClient)
        self.logService = .init(appDependencies)
        self.action = action
        self.id = id
        self.bookmarkState = bookmarkState
        self.isPresentedFileImporter = isPresentedFileImporter
    }

    public func send(_ action: Action) async {
        await self.action(action)

        switch action {
        case let .task(screenName):
            logService.notice(.screenView(name: screenName))
            bookmarkState = bookmarkRepository.bookmarkState

        case .grantPermissionButtonTapped:
            isPresentedFileImporter = true

        case let .onCompletionGrantPermission(result):
            switch result {
            case let .success(url) where url == homeDirectory:
                do {
                    try bookmarkRepository.set(url)
                    bookmarkState = bookmarkRepository.bookmarkState
                } catch {
                    logService.critical(.failedSaveBookmark(error))
                }
            case .success:
                logService.error(.selectedItemIsNotHomeDirectory)
            case let .failure(error):
                logService.critical(.failedGrantingPermission(error))
            }

        case .setUpLaterButtonTapped:
            break

        case .revokePermissionButtonTapped:
            bookmarkRepository.remove()
            bookmarkState = bookmarkRepository.bookmarkState

        case .closeButtonTapped:
            break
        }
    }

    public enum Action {
        case task(String)
        case grantPermissionButtonTapped
        case onCompletionGrantPermission(Result<URL, any Error>)
        case setUpLaterButtonTapped
        case revokePermissionButtonTapped
        case closeButtonTapped
    }
}
