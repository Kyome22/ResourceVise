/*
 ExportFile.swift
 DataSource

 Created by Takuto Nakamura on 2024/11/30.
 
*/

import SwiftUI

public struct ExportFile: Transferable {
    var exportHandler: @Sendable () async throws -> URL

    public init(exportHandler: @escaping @Sendable () async throws -> URL) {
        self.exportHandler = exportHandler
    }

    public static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .mpeg4Movie) { exportFile in
            try await SentTransferredFile(exportFile.exportHandler())
        }
    }
}
