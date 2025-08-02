/*
 NSImageClient.swift
 LocalPackage

 Created by Takuto Nakamura on 2025/08/02.
 
*/

import AppKit.NSImage

public struct NSImageClient: DependencyClient {
    public var contentsOf: @Sendable (URL) -> NSImage?
    public var cgImage: @Sendable (NSImage) -> CGImage?

    public static let liveValue = Self(
        contentsOf: { NSImage(contentsOf: $0) },
        cgImage: { $0.cgImage(forProposedRect: nil, context: nil, hints: nil) }
    )

    public static let testValue = Self(
        contentsOf: { _ in nil },
        cgImage: { _ in nil }
    )
}
