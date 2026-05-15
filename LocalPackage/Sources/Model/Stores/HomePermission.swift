/*
 HomePermission.swift
 Model

 Created by Takuto Nakamura on 2025/08/02.
 
*/

import DataSource
import Foundation
import Observation

@MainActor @Observable
public final class HomePermission: Composable, Identifiable {
    private let appStateClient: AppStateClient
    private let bookmarkRepository: BookmarkRepository
    private let logService: LogService

    public let id: UUID
    public var bookmarkState: BookmarkState
    public var isPresentedFileImporter: Bool
    public let action: (Action) async -> Void

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
        action: @escaping (Action) async -> Void = { _ in }
    ) {
        self.appStateClient = appDependencies.appStateClient
        self.bookmarkRepository = .init(appDependencies.urlClient, appDependencies.userDefaultsClient)
        self.logService = .init(appDependencies)
        self.id = id
        self.bookmarkState = bookmarkState
        self.isPresentedFileImporter = isPresentedFileImporter
        self.action = action
    }

    public func reduce(_ action: Action) async {
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
            return

        case .revokePermissionButtonTapped:
            bookmarkRepository.remove()
            bookmarkState = bookmarkRepository.bookmarkState

        case .closeButtonTapped:
            return
        }
    }

    public enum Action: Sendable {
        case task(String)
        case grantPermissionButtonTapped
        case onCompletionGrantPermission(Result<URL, any Error>)
        case setUpLaterButtonTapped
        case revokePermissionButtonTapped
        case closeButtonTapped
    }
}
