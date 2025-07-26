/*
 ImageConvertService.swift
 Model

 Created by Takuto Nakamura on 2024/11/17.
 
*/

import AppKit
import DataSource
import WebPEncoder

public struct ImageConvertService {
    private let appStateClient: AppStateClient
    private let fileManagerClient: FileManagerClient

    public init(_ appDependencies: AppDependencies) {
        self.appStateClient = appDependencies.appStateClient
        self.fileManagerClient = appDependencies.fileManagerClient
    }

    public func imageFiles(urls: [URL]) -> [ImageFile] {
        urls.compactMap { url in
            guard url.startAccessingSecurityScopedResource() else { return nil }
            let attributes: [FileAttributeKey : Any]? = {
                do {
                    return try fileManagerClient.attributesOfItem(url.path(percentEncoded: false))
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

    public func exportFolder(imageFiles: [ImageFile]) -> ExportFolder? {
        guard !imageFiles.isEmpty else { return nil }
        return ExportFolder { [copy = imageFiles, appStateClient] in
            let encoder = WebPEncoder()
            return copy.enumerated().compactMap { index, imageFile -> WebPFile? in
                let value = Double(index + 1) / Double(copy.count)
                guard let nsImage = NSImage(contentsOf: imageFile.url),
                      let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                    appStateClient.withLock { $0.progressSubject.send(value) }
                    return nil
                }
                do {
                    let webpData = try encoder.encode(cgImage, config: .preset(.picture, quality: 0.9, multithread: false))
                    appStateClient.withLock { $0.progressSubject.send(value) }
                    return WebPFile(originalURL: imageFile.url, data: webpData)
                } catch {
                    print(error.localizedDescription)
                    return nil
                }
            }
        }
    }
}
