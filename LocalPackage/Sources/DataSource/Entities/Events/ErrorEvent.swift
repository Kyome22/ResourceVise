/*
 ErrorEvent.swift
 DataSource

 Created by Takuto Nakamura on 2024/11/13.

*/

import Logging

public enum ErrorEvent {
    case selectedItemIsNotHomeDirectory
    case failedToReadTemporaryDirectory(any Error)
    case failedToRemoveTemporaryFile(any Error)

    public var message: Logger.Message {
        switch self {
        case .selectedItemIsNotHomeDirectory:
            "Selected item is not home directory."
        case .failedToReadTemporaryDirectory:
            "Failed to read temporary directory."
        case .failedToRemoveTemporaryFile:
            "Failed to remove temporary file."
        }
    }

    public var metadata: Logger.Metadata? {
        switch self {
        case .selectedItemIsNotHomeDirectory:
            nil
        case let .failedToReadTemporaryDirectory(error),
             let .failedToRemoveTemporaryFile(error):
            ["cause": .string(error.localizedDescription)]
        }
    }
}
