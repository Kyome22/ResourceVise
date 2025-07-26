/*
 ImageVise.swift
 Model

 Created by Takuto Nakamura on 2024/11/30.
 
*/

import Foundation
import DataSource
import Observation

@MainActor @Observable public final class ImageVise {
    private let appStateClient: AppStateClient
    private let nsWorkspaceClient: NSWorkspaceClient
    private let imageConvertService: ImageConvertService
    private let logService: LogService

    @ObservationIgnored private var task: Task<Void, Never>?

    public var isPresentedFileImporter: Bool
    public var isPresentedFileExporter: Bool
    public var isProcessing: Bool
    public var progressValue: Double
    public var imageFiles: [ImageFile]

    public var disableToExport: Bool {
        imageFiles.isEmpty
    }
    public var exportFolder: ExportFolder? {
        imageConvertService.exportFolder(imageFiles: imageFiles)
    }

    public init(
        _ appDependencies: AppDependencies,
        isPresentedFileImporter: Bool = false,
        isPresentedFileExporter: Bool = false,
        isProcessing: Bool = false,
        progressValue: Double = .zero,
        imageFiles: [ImageFile] = []
    ) {
        self.appStateClient = appDependencies.appStateClient
        self.nsWorkspaceClient = appDependencies.nsWorkspaceClient
        self.imageConvertService = .init(appDependencies)
        self.logService = .init(appDependencies)
        self.isPresentedFileImporter = isPresentedFileImporter
        self.isPresentedFileExporter = isPresentedFileExporter
        self.isProcessing = isProcessing
        self.progressValue = progressValue
        self.imageFiles = imageFiles
    }

    public func send(_ aciton: Action) {
        switch aciton {
        case let .onAppear(screenName):
            logService.notice(.screenView(name: screenName))
            task = Task { [weak self, appStateClient] in
                let values = appStateClient.withLock(\.progressSubject.values)
                for await value in values {
                    self?.progressValue = value
                }
            }

        case .onDisappear:
            task?.cancel()

        case .importButtonTapped:
            isPresentedFileImporter = true

        case .exportButtonTapped:
            isPresentedFileExporter = true
            isProcessing = true

        case let .onCompletionFileImport(result):
            switch result {
            case let .success(urls):
                imageFiles = imageConvertService.imageFiles(urls: urls)
            case let .failure(error):
                print(error.localizedDescription)
            }

        case let .onCompletionFileExport(result):
            isProcessing = false
            progressValue = .zero
            imageFiles.removeAll()
            switch result {
            case let .success(url):
                if let appURL = nsWorkspaceClient.urlForApplication("com.apple.Finder") {
                    nsWorkspaceClient.open([url], appURL)
                }
            case let .failure(error):
                print(error.localizedDescription)
            }

        case .onCancellationFileExport:
            isProcessing = false
            progressValue = .zero
            imageFiles.removeAll()
        }
    }

    public enum Action {
        case onAppear(String)
        case onDisappear
        case importButtonTapped
        case exportButtonTapped
        case onCompletionFileImport(Result<[URL], any Error>)
        case onCompletionFileExport(Result<URL, any Error>)
        case onCancellationFileExport
    }
}
