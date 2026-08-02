/*
 ImageFile.swift
 DataSource

 Created by Takuto Nakamura on 2024/11/17.
 
*/

import CoreGraphics
import Foundation

public struct ImageFile: Identifiable, Sendable {
    public var id = UUID()
    public var url: URL
    public var size: String
    public var thumbnail: CGImage?

    public var filename: String {
        url.lastPathComponent
    }

    public init(url: URL, size: String, thumbnail: CGImage? = nil) {
        self.url = url
        self.size = size
        self.thumbnail = thumbnail
    }
}
