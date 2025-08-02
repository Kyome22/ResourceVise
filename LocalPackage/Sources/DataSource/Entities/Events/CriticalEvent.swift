/*
 CriticalEvent.swift
 DataSource

 Created by Takuto Nakamura on 2024/11/13.
 
*/

import Logging

public enum CriticalEvent {
    case failedWriteData(any Error)
    case failedSaveFile(any Error)
    case failedSaveBookmark(any Error)
    case failedGrantingPermission(any Error)
    case failedRenameFiles(any Error)

    public var message: Logger.Message {
        switch self {
        case .failedWriteData:
            "Failed to write data."
        case .failedSaveFile:
            "Failed to save file."
        case .failedSaveBookmark:
            "Failed to save bookmark."
        case .failedGrantingPermission:
            "Failed granting permission to control home directory."
        case .failedRenameFiles:
            "Failed to rename files."
        }
    }

    public var metadata: Logger.Metadata? {
        switch self {
        case let .failedWriteData(error),
            let .failedSaveFile(error),
            let .failedSaveBookmark(error),
            let .failedGrantingPermission(error),
            let .failedRenameFiles(error):
            ["cause": "\(error.localizedDescription)"]
        }
    }
}
