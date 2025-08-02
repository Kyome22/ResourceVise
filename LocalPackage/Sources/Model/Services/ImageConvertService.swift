/*
 ImageConvertService.swift
 Model

 Created by Takuto Nakamura on 2024/11/17.
 
*/

import DataSource
import Foundation
import WebPEncoder

struct ImageConvertService {
    private let appStateClient: AppStateClient
    private let dataClient: DataClient
    private let fileManagerClient: FileManagerClient
    private let nsImageClient: NSImageClient

    init(_ appDependencies: AppDependencies) {
        self.appStateClient = appDependencies.appStateClient
        self.dataClient = appDependencies.dataClient
        self.fileManagerClient = appDependencies.fileManagerClient
        self.nsImageClient = appDependencies.nsImageClient
    }

    func setHomeDirectory() {
        appStateClient.withLock { [fileManagerClient] in
            $0.homeDirectory = fileManagerClient
                .homeDirectoryForCurrentUser()
                .pathComponents
                .prefix(3)
                .reduce {
                    URL(filePath: $0)
                } successor: {
                    $0.append(path: $1, directoryHint: .isDirectory)
                }
        }
    }

    func imageFiles(urls: [URL]) -> [ImageFile] {
        urls.compactMap { url in
            let attributes: [FileAttributeKey : Any]? = {
                do {
                    let path = url.absoluteURL.path(percentEncoded: false)
                    return try fileManagerClient.attributesOfItem(path)
                } catch {
                    print(error.localizedDescription)
                    return nil
                }
            }()
            guard let attributes, let size = attributes[.size] as? UInt64 else { return nil }
            let fileSize = ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
            return ImageFile(url: url, size: fileSize)
        }
    }

    private func uniqueFileURL(for originalURL: URL) -> URL {
        let baseName = originalURL.deletingPathExtension().lastPathComponent
        let pathExtension = originalURL.pathExtension
        var uniqueURL = originalURL
        var counter = 2
        while fileManagerClient.fileExists(uniqueURL.absoluteURL.path(percentEncoded: false)) {
            let newFileName = "\(baseName) \(counter)"
            uniqueURL = originalURL.deletingLastPathComponent()
                .appendingPathComponent(newFileName)
                .appendingPathExtension(pathExtension)
            counter += 1
        }
        return uniqueURL
    }

    func convert(imageFiles: [ImageFile], percentage: Int, deleteOriginal: Bool) async {
        guard !imageFiles.isEmpty else { return }
        let total = imageFiles.count
        let ratio = CGFloat(percentage) / 100
        let encoder = WebPEncoder()
        for (offset, imageFile) in imageFiles.enumerated() {
            let value = Double(offset + 1) / Double(total)
            guard let nsImage = nsImageClient.contentsOf(imageFile.url),
                  let cgImage = nsImageClient.cgImage(nsImage),
                  let resizedCGImage = cgImage.resize(ratio: ratio) else {
                continue
            }
            do {
                let config = WebPEncoderConfig.preset(.picture, quality: 0.9, multithread: false)
                let webpData = try encoder.encode(resizedCGImage, config: config)
                appStateClient.withLock { $0.progressSubject.send(value) }
                let fileURL = imageFile.url.deletingPathExtension().appendingPathExtension("webp")
                let isSameFileName = imageFile.url.compare(with: fileURL)
                switch (deleteOriginal, isSameFileName) {
                case (true, true):
                    try fileManagerClient.removeItem(imageFile.url)
                    try dataClient.write(webpData, fileURL)

                case (true, false):
                    try dataClient.write(webpData, fileURL)
                    try fileManagerClient.removeItem(imageFile.url)

                case (false, true):
                    try dataClient.write(webpData, uniqueFileURL(for: fileURL))

                case (false, false):
                    try dataClient.write(webpData, fileURL)
                }
            } catch {
                print(error.localizedDescription)
                continue
            }
        }
    }
}
