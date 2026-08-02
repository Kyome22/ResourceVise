import Foundation
import os
import Testing

@testable import DataSource
@testable import Model

struct TemporaryFileCleanupServiceTests {
    private let temporaryDirectory = URL(filePath: "/Users/test/tmp", directoryHint: .isDirectory)

    @Test
    func cleanUp_removes_every_item_directly_under_temporary_directory() async {
        let removedFilenames = OSAllocatedUnfairLock<[String]>(initialState: [])
        let temporaryDirectory = temporaryDirectory
        let service = TemporaryFileCleanupService(.testDependencies(
            fileManagerClient: testDependency(of: FileManagerClient.self) {
                $0.temporaryDirectory = { temporaryDirectory }
                $0.contentsOfDirectory = { _, _ in
                    [
                        temporaryDirectory.appending(path: "CFNetworkDownload_AAAAAA.tmp"),
                        temporaryDirectory.appending(path: "CFNetworkDownload_BBBBBB.tmp"),
                    ]
                }
                $0.attributesOfItem = { _ in [.size: UInt64(1024)] }
                $0.removeItem = { url in
                    removedFilenames.withLock { $0.append(url.lastPathComponent) }
                }
            }
        ))
        await service.cleanUp()
        #expect(removedFilenames.withLock(\.self) == [
            "CFNetworkDownload_AAAAAA.tmp",
            "CFNetworkDownload_BBBBBB.tmp",
        ])
    }

    @Test
    func cleanUp_skips_items_outside_temporary_directory() async {
        let removedFilenames = OSAllocatedUnfairLock<[String]>(initialState: [])
        let temporaryDirectory = temporaryDirectory
        let service = TemporaryFileCleanupService(.testDependencies(
            fileManagerClient: testDependency(of: FileManagerClient.self) {
                $0.temporaryDirectory = { temporaryDirectory }
                $0.contentsOfDirectory = { _, _ in
                    [
                        URL(filePath: "/Users/test/Pictures/photo.jpg"),
                        temporaryDirectory
                            .appending(path: "nested", directoryHint: .isDirectory)
                            .appending(path: "deep.tmp"),
                    ]
                }
                $0.removeItem = { url in
                    removedFilenames.withLock { $0.append(url.lastPathComponent) }
                }
            }
        ))
        await service.cleanUp()
        #expect(removedFilenames.withLock(\.self).isEmpty)
    }

    @Test
    func cleanUp_continues_when_remove_item_throws() async {
        let removedFilenames = OSAllocatedUnfairLock<[String]>(initialState: [])
        let temporaryDirectory = temporaryDirectory
        let service = TemporaryFileCleanupService(.testDependencies(
            fileManagerClient: testDependency(of: FileManagerClient.self) {
                $0.temporaryDirectory = { temporaryDirectory }
                $0.contentsOfDirectory = { _, _ in
                    [
                        temporaryDirectory.appending(path: "locked.tmp"),
                        temporaryDirectory.appending(path: "removable.tmp"),
                    ]
                }
                $0.removeItem = { url in
                    guard url.lastPathComponent != "locked.tmp" else {
                        throw URLError(.unknown)
                    }
                    removedFilenames.withLock { $0.append(url.lastPathComponent) }
                }
            }
        ))
        await service.cleanUp()
        #expect(removedFilenames.withLock(\.self) == ["removable.tmp"])
    }

    @Test
    func cleanUp_removes_nothing_when_contents_of_directory_throws() async {
        let removedFilenames = OSAllocatedUnfairLock<[String]>(initialState: [])
        let service = TemporaryFileCleanupService(.testDependencies(
            fileManagerClient: testDependency(of: FileManagerClient.self) {
                $0.contentsOfDirectory = { _, _ in throw URLError(.unknown) }
                $0.removeItem = { url in
                    removedFilenames.withLock { $0.append(url.lastPathComponent) }
                }
            }
        ))
        await service.cleanUp()
        #expect(removedFilenames.withLock(\.self).isEmpty)
    }
}
