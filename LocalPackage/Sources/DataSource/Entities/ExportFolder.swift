/*
 ExportFolder.swift
 DataSource

 Created by Takuto Nakamura on 2024/11/17.
 
*/

import SwiftUI
import UniformTypeIdentifiers

public struct ExportFolder: FileDocument {
    public static let readableContentTypes: [UTType] = [.folder]

    let generateHandler: @Sendable () throws -> [WebPFile]

    public init(generateHandler: @escaping @Sendable () throws -> [WebPFile]) {
        self.generateHandler = generateHandler
    }

    public init(configuration: ReadConfiguration) throws {
        fatalError()
    }
    
    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let files = try generateHandler()
        let fileWrappers = files.reduce(into: [String: FileWrapper]()) {
            $0[$1.filename] = FileWrapper(regularFileWithContents: $1.data)
        }
        return FileWrapper(directoryWithFileWrappers: fileWrappers)
    }
}
