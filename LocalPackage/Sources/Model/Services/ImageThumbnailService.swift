/*
 ImageThumbnailService.swift
 Model

 Created by Takuto Nakamura on 2026/08/02.

*/

import CoreGraphics
import DataSource
import Foundation
import ImageIO

struct ImageThumbnailService {
    private static let maxPixelSize = 50

    private let cgImageSourceClient: CGImageSourceClient

    init(_ appDependencies: AppDependencies) {
        self.cgImageSourceClient = appDependencies.cgImageSourceClient
    }

    nonisolated func thumbnail(url: URL) async -> CGImage? {
        guard let imageSource = cgImageSourceClient.createWithURL(url) else {
            return nil
        }
        let options: [CFString : Any] = [
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: Self.maxPixelSize,
        ]
        return cgImageSourceClient.createThumbnailAtIndex(imageSource, .zero, options as CFDictionary)
    }
}
