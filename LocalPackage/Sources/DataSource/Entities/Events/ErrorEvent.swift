/*
 ErrorEvent.swift
 DataSource

 Created by Takuto Nakamura on 2024/11/13.
 
*/

import Logging

public enum ErrorEvent {
    case selectedItemIsNotHomeDirectory

    public var message: Logger.Message {
        switch self {
        case .selectedItemIsNotHomeDirectory:
            "Selected item is not home directory."
        }
    }
    public var metadata: Logger.Metadata? { nil }
}
