/*
 CGImageSourceClient.swift
 DataSource

 Created by Takuto Nakamura on 2026/08/02.

*/

import Foundation
import ImageIO

public struct CGImageSourceClient: DependencyClient {
    public var createWithURL: @Sendable (URL) -> CGImageSource?
    public var createThumbnailAtIndex: @Sendable (CGImageSource, Int, CFDictionary) -> CGImage?

    public static let liveValue = Self(
        createWithURL: { CGImageSourceCreateWithURL($0 as CFURL, nil) },
        createThumbnailAtIndex: { CGImageSourceCreateThumbnailAtIndex($0, $1, $2) }
    )

    public static let testValue = Self(
        createWithURL: { _ in nil },
        createThumbnailAtIndex: { _, _, _ in nil }
    )
}
