/*
 ImageVise.swift
 Model

 Created by Takuto Nakamura on 2024/11/30.

*/

import Foundation
import DataSource
import Observation
import UniformTypeIdentifiers

@MainActor @Observable
public final class ImageVise: Composable {
    private let appDependencies: AppDependencies
    private let appStateClient: AppStateClient
    private let bookmarkRepository: BookmarkRepository
    private let imageConvertService: ImageConvertService
    private let imageThumbnailService: ImageThumbnailService
    private let logService: LogService

    @ObservationIgnored private var task: Task<Void, Never>?

    public var bookmarkState: BookmarkState
    public var percentage: Int
    public var quality: Int
    public var deleteOriginal: Bool
    public var isPresentedFileImporter: Bool
    public var isProcessing: Bool
    public var progressValue: Double
    public var imageFiles: [ImageFile]
    public var homePermission: HomePermission?
    public let action: (Action) async -> Void

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
        quality: Int = 90,
        deleteOriginal: Bool = true,
        isPresentedFileImporter: Bool = false,
        isProcessing: Bool = false,
        progressValue: Double = .zero,
        imageFiles: [ImageFile] = [],
        homePermission: HomePermission? = nil,
        action: @escaping (Action) async -> Void = { _ in }
    ) {
        self.appDependencies = appDependencies
        self.appStateClient = appDependencies.appStateClient
        self.bookmarkRepository = .init(appDependencies.urlClient, appDependencies.userDefaultsClient)
        self.imageConvertService = .init(appDependencies)
        self.imageThumbnailService = .init(appDependencies)
        self.logService = .init(appDependencies)
        self.bookmarkState = bookmarkState
        self.percentage = percentage
        self.quality = quality
        self.deleteOriginal = deleteOriginal
        self.isPresentedFileImporter = isPresentedFileImporter
        self.isProcessing = isProcessing
        self.progressValue = progressValue
        self.imageFiles = imageFiles
        self.homePermission = homePermission
        self.action = action
    }

    public func reduce(_ action: Action) async {
        switch action {
        case let .viewAppeared(screenName):
            logService.notice(.screenView(name: screenName))
            if let latestProgress = appStateClient.withLock(\.progress.latestValue) {
                progressValue = latestProgress
            }
            task?.cancel()
            task = Task { [weak self, appStateClient] in
                let stream = appStateClient.withLock(\.progress.stream)
                for await value in stream {
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

        case .viewDisappeared:
            task?.cancel()
            task = nil

        case .importButtonTapped:
            isPresentedFileImporter = true

        case let .imageFileAppeared(id):
            guard let imageFile = imageFiles.first(where: { $0.id == id }),
                  imageFile.thumbnail == nil,
                  let thumbnail = await imageThumbnailService.thumbnail(url: imageFile.url),
                  let index = imageFiles.firstIndex(where: { $0.id == id }) else {
                return
            }
            imageFiles[index].thumbnail = thumbnail

        case .convertButtonTapped:
            isProcessing = true
            await imageConvertService.convert(
                imageFiles: imageFiles,
                percentage: percentage,
                quality: quality,
                deleteOriginal: deleteOriginal
            )
            imageFiles.removeAll()
            isProcessing = false

        case let .fileImportCompleted(result):
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

        case .homePermissionButtonTapped:
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
            return
        }
    }

    public enum Action: Sendable {
        case viewAppeared(String)
        case viewDisappeared
        case importButtonTapped
        case imageFileAppeared(ImageFile.ID)
        case convertButtonTapped
        case fileImportCompleted(Result<[URL], any Error>)
        case homePermissionButtonTapped
        case homePermission(HomePermission.Action)
    }
}
