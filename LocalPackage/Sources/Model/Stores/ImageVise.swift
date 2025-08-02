/*
 ImageVise.swift
 Model

 Created by Takuto Nakamura on 2024/11/30.
 
*/

import Foundation
import DataSource
import Observation
import UniformTypeIdentifiers

@MainActor @Observable public final class ImageVise {
    private let appStateClient: AppStateClient
    private let nsWorkspaceClient: NSWorkspaceClient
    private let bookmarkRepository: BookmarkRepository
    private let imageConvertService: ImageConvertService
    private let logService: LogService

    @ObservationIgnored private var task: Task<Void, Never>?

    public var bookmarkState: BookmarkState
    public var percentage: Int
    public var deleteOriginal: Bool
    public var isPresentedFileImporter: Bool
    public var isProcessing: Bool
    public var progressValue: Double
    public var imageFiles: [ImageFile]
    public var homePermission: HomePermission?
    public var homeDirectory: URL? {
        appStateClient.withLock(\.homeDirectory)
    }
    public var disableToConvert: Bool {
        imageFiles.isEmpty
    }

    public init(
        _ appDependencies: AppDependencies,
        bookmarkState: BookmarkState = .notSaved,
        percentage: Int = 100,
        deleteOriginal: Bool = true,
        isPresentedFileImporter: Bool = false,
        isProcessing: Bool = false,
        progressValue: Double = .zero,
        imageFiles: [ImageFile] = [],
        homePermission: HomePermission? = nil
    ) {
        self.appStateClient = appDependencies.appStateClient
        self.nsWorkspaceClient = appDependencies.nsWorkspaceClient
        self.bookmarkRepository = .init(appDependencies.urlClient, appDependencies.userDefaultsClient)
        self.imageConvertService = .init(appDependencies)
        self.logService = .init(appDependencies)
        self.bookmarkState = bookmarkState
        self.percentage = percentage
        self.deleteOriginal = deleteOriginal
        self.isPresentedFileImporter = isPresentedFileImporter
        self.isProcessing = isProcessing
        self.progressValue = progressValue
        self.imageFiles = imageFiles
        self.homePermission = homePermission
    }

    public func send(_ aciton: Action) async {
        switch aciton {
        case let .task(appDependencies, screenName):
            logService.notice(.screenView(name: screenName))
            task = Task { [weak self, appStateClient] in
                let values = appStateClient.withLock(\.progressSubject.values)
                for await value in values {
                    self?.progressValue = value
                }
            }
            bookmarkState = bookmarkRepository.bookmarkState
            switch bookmarkState {
            case .notSaved:
                homePermission = .init(appDependencies, action: { [weak self] in
                    await self?.send(.homePermission($0))
                })
            case .saved:
                _ = bookmarkRepository.enable()
            }

        case .onDisappear:
            task?.cancel()

        case .importButtonTapped:
            isPresentedFileImporter = true

        case .convertButtonTapped:
            isProcessing = true
            await imageConvertService.convert(
                imageFiles: imageFiles,
                percentage: percentage,
                deleteOriginal: deleteOriginal
            )
            imageFiles.removeAll()
            isProcessing = false

        case let .onCompletionFileImport(appDependencies, result):
            switch result {
            case let .success(urls):
                switch bookmarkRepository.bookmarkState {
                case .notSaved:
                    homePermission = .init(appDependencies, action: { [weak self] in
                        await self?.send(.homePermission($0))
                    })
                case .saved:
                    imageFiles = imageConvertService.imageFiles(urls: urls)
                }
            case let .failure(error):
                print(error.localizedDescription)
            }

        case let .homePermissionButtonTapped(appDependencies):
            homePermission = .init(appDependencies, action: { [weak self] in
                await self?.send(.homePermission($0))
            })

        case .homePermission(.setUpLaterButtonTapped), .homePermission(.closeButtonTapped):
            homePermission = nil
            bookmarkState = bookmarkRepository.bookmarkState
            if bookmarkState == .saved {
                _ = bookmarkRepository.enable()
            }

        case .homePermission:
            break
        }
    }

    public enum Action {
        case task(AppDependencies, String)
        case onDisappear
        case importButtonTapped
        case convertButtonTapped
        case onCompletionFileImport(AppDependencies, Result<[URL], any Error>)
        case homePermissionButtonTapped(AppDependencies)
        case homePermission(HomePermission.Action)
    }
}
