/*
 TemporaryFileCleanupService.swift
 Model

 Created by Takuto Nakamura on 2026/08/02.

*/

import DataSource
import Foundation

struct TemporaryFileCleanupService {
    private let fileManagerClient: FileManagerClient
    private let logService: LogService

    init(_ appDependencies: AppDependencies) {
        self.fileManagerClient = appDependencies.fileManagerClient
        self.logService = .init(appDependencies)
    }

    nonisolated func cleanUp() async {
        let temporaryDirectory = fileManagerClient.temporaryDirectory()
        let contents: [URL]
        do {
            contents = try fileManagerClient.contentsOfDirectory(
                temporaryDirectory,
                [.skipsSubdirectoryDescendants]
            )
        } catch {
            logService.error(.failedToReadTemporaryDirectory(error))
            return
        }
        var fileCount = Int.zero
        var byteCount = Int64.zero
        for url in contents where url.deletingLastPathComponent().compare(with: temporaryDirectory) {
            let path = url.absoluteURL.path(percentEncoded: false)
            let attributes = try? fileManagerClient.attributesOfItem(path)
            let size = (attributes?[.size] as? UInt64) ?? .zero
            do {
                try fileManagerClient.removeItem(url)
                fileCount += 1
                byteCount += Int64(size)
            } catch {
                logService.error(.failedToRemoveTemporaryFile(error))
            }
        }
        guard fileCount > .zero else { return }
        logService.notice(.cleanedUpTemporaryDirectory(fileCount: fileCount, byteCount: byteCount))
    }
}
