import CoreGraphics
import Foundation
import ImageIO
import os
import Testing

@testable import DataSource
@testable import Model

struct ImageThumbnailServiceTests {
    @Test
    func thumbnail_requests_transformed_thumbnail_limited_to_50_pixels() async {
        let recordedMaxPixelSize = OSAllocatedUnfairLock<Int?>(initialState: nil)
        let recordedWithTransform = OSAllocatedUnfairLock<Bool?>(initialState: nil)
        let service = ImageThumbnailService(.testDependencies(
            cgImageSourceClient: testDependency(of: CGImageSourceClient.self) {
                $0.createWithURL = { _ in CGImageSource.dummy() }
                $0.createThumbnailAtIndex = { _, _, options in
                    let dictionary = options as? [CFString : Any]
                    let maxPixelSize = dictionary?[kCGImageSourceThumbnailMaxPixelSize] as? Int
                    let withTransform = dictionary?[kCGImageSourceCreateThumbnailWithTransform] as? Bool
                    recordedMaxPixelSize.withLock { $0 = maxPixelSize }
                    recordedWithTransform.withLock { $0 = withTransform }
                    return CGImage.dummy()
                }
            }
        ))
        let thumbnail = await service.thumbnail(url: URL(filePath: "/Users/test/photo.jpg"))
        #expect(thumbnail != nil)
        #expect(recordedMaxPixelSize.withLock(\.self) == 50)
        #expect(recordedWithTransform.withLock(\.self) == true)
    }

    @Test
    func thumbnail_returns_nil_when_image_source_is_unavailable() async {
        let service = ImageThumbnailService(.testDependencies())
        let thumbnail = await service.thumbnail(url: URL(filePath: "/Users/test/broken.jpg"))
        #expect(thumbnail == nil)
    }
}
