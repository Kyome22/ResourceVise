/*
 WebPFile.swift
 DataSource

 Created by Takuto Nakamura on 2024/11/17.
 
*/

import Foundation

public struct WebPFile: Sendable {
    public var filename: String
    public var data: Data

    public init(originalURL: URL, data: Data) {
        self.filename = originalURL.deletingPathExtension().appendingPathExtension("webp").lastPathComponent
        self.data = data
    }
}
