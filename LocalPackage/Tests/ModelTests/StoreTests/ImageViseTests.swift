import CoreGraphics
import Foundation
import ImageIO
import os
import Testing

@testable import DataSource
@testable import Model

struct ImageViseTests {
    @MainActor @Test
    func send_thumbnailTask_sets_thumbnail_of_matching_image_file() async {
        let thumbnail = CGImage.dummy()
        let store = ImageVise(
            .testDependencies(
                cgImageSourceClient: testDependency(of: CGImageSourceClient.self) {
                    $0.createWithURL = { _ in CGImageSource.dummy() }
                    $0.createThumbnailAtIndex = { _, _, _ in thumbnail }
                }
            ),
            imageFiles: [ImageFile(url: URL(filePath: "/Users/test/photo.jpg"), size: "1 KB")]
        )
        await store.send(.thumbnailTask(store.imageFiles[0].id))
        #expect(store.imageFiles[0].thumbnail === thumbnail)
    }

    @MainActor @Test
    func send_thumbnailTask_does_not_decode_again_when_thumbnail_is_loaded() async {
        let createCallCount = OSAllocatedUnfairLock<Int>(initialState: 0)
        let store = ImageVise(
            .testDependencies(
                cgImageSourceClient: testDependency(of: CGImageSourceClient.self) {
                    $0.createWithURL = { _ in
                        createCallCount.withLock { $0 += 1 }
                        return CGImageSource.dummy()
                    }
                }
            ),
            imageFiles: [
                ImageFile(
                    url: URL(filePath: "/Users/test/photo.jpg"),
                    size: "1 KB",
                    thumbnail: .dummy()
                ),
            ]
        )
        await store.send(.thumbnailTask(store.imageFiles[0].id))
        #expect(createCallCount.withLock(\.self) == 0)
    }

    @MainActor @Test
    func send_thumbnailTask_ignores_unknown_identifier() async {
        let createCallCount = OSAllocatedUnfairLock<Int>(initialState: 0)
        let store = ImageVise(
            .testDependencies(
                cgImageSourceClient: testDependency(of: CGImageSourceClient.self) {
                    $0.createWithURL = { _ in
                        createCallCount.withLock { $0 += 1 }
                        return CGImageSource.dummy()
                    }
                }
            )
        )
        await store.send(.thumbnailTask(UUID()))
        #expect(createCallCount.withLock(\.self) == 0)
    }
}
