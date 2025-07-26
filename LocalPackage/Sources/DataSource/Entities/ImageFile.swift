/*
 ImageFile.swift
 DataSource

 Created by Takuto Nakamura on 2024/11/17.
 
*/

import Foundation

public struct ImageFile: Identifiable, Sendable {
    public var id = UUID()
    public var url: URL
    public var size: String

    public var filename: String {
        url.lastPathComponent
    }

    public init(url: URL, size: String) {
        self.url = url
        self.size = size
    }
}
