/*
 NoticeEvent.swift
 DataSource

 Created by Takuto Nakamura on 2024/11/13.
 
*/

import Logging

public enum NoticeEvent {
    case launchApp
    case screenView(name: String)
    case cleanedUpTemporaryDirectory(fileCount: Int, byteCount: Int64)

    public var message: Logger.Message {
        switch self {
        case .launchApp:
            "launch_app"
        case .screenView:
            "screen_view"
        case .cleanedUpTemporaryDirectory:
            "cleaned_up_temporary_directory"
        }
    }

    public var metadata: Logger.Metadata? {
        switch self {
        case .launchApp:
            [:]
        case let .screenView(name):
            ["screen": .string(name)]
        case let .cleanedUpTemporaryDirectory(fileCount, byteCount):
            [
                "file_count": .stringConvertible(fileCount),
                "byte_count": .stringConvertible(byteCount),
            ]
        }
    }
}
