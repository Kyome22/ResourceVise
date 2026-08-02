import AppKit
import CoreGraphics
import Foundation
import ImageIO
import os
import Testing

@testable import DataSource
@testable import Model

@MainActor
struct ImageViseTests {
    private let homeDirectory = URL(filePath: "/Users/test", directoryHint: .isDirectory)

    private func savedBookmarkUserDefaultsClient() -> UserDefaultsClient {
        testDependency(of: UserDefaultsClient.self) {
            $0.object = { _ in Data([1, 2, 3]) }
            $0.data = { _ in Data([1, 2, 3]) }
        }
    }

    @Test
    func send_viewAppeared_bookmarkIsNotSaved_homePermissionIsPresented() async {
        let store = ImageVise(.testDependencies())
        await store.send(.viewAppeared("ImageViseView"))
        #expect(store.homePermission != nil)
        #expect(store.bookmarkState == .notSaved)
        await store.send(.viewDisappeared)
    }

    @Test
    func send_viewAppeared_bookmarkIsSaved_securityScopedResourceIsStarted() async {
        let startedURLs = OSAllocatedUnfairLock<[URL]>(initialState: [])
        let homeDirectory = homeDirectory
        let store = ImageVise(.testDependencies(
            urlClient: testDependency(of: URLClient.self) {
                $0.create = { _, _ in (false, homeDirectory) }
                $0.startAccessingSecurityScopedResource = { url in
                    startedURLs.withLock { $0.append(url) }
                    return true
                }
            },
            userDefaultsClient: savedBookmarkUserDefaultsClient()
        ))
        await store.send(.viewAppeared("ImageViseView"))
        #expect(store.homePermission == nil)
        #expect(store.bookmarkState == .saved)
        #expect(startedURLs.withLock(\.self) == [homeDirectory])
        await store.send(.viewDisappeared)
    }

    @Test
    func send_viewAppeared_latestProgressIsRestored() async {
        let appState = OSAllocatedUnfairLock<AppState>(initialState: .init())
        appState.withLock { $0.progress.send(0.5) }
        let store = ImageVise(.testDependencies(appStateClient: .testDependency(appState)))
        await store.send(.viewAppeared("ImageViseView"))
        #expect(store.progressValue == 0.5)
        await store.send(.viewDisappeared)
    }

    @Test
    func send_viewAppeared_progressOfConversionIsObserved() async {
        let appState = OSAllocatedUnfairLock<AppState>(initialState: .init())
        let store = ImageVise(.testDependencies(appStateClient: .testDependency(appState)))
        await store.send(.viewAppeared("ImageViseView"))
        appState.withLock { $0.progress.send(0.5) }
        await waitUntil { store.progressValue == 0.5 }
        #expect(store.progressValue == 0.5)
        await store.send(.viewDisappeared)
    }

    @Test
    func send_viewDisappeared_progressIsNoLongerObserved() async {
        let appState = OSAllocatedUnfairLock<AppState>(initialState: .init())
        let store = ImageVise(.testDependencies(appStateClient: .testDependency(appState)))
        await store.send(.viewAppeared("ImageViseView"))
        appState.withLock { $0.progress.send(0.5) }
        await waitUntil { store.progressValue == 0.5 }
        await store.send(.viewDisappeared)
        appState.withLock { $0.progress.send(1) }
        try? await Task.sleep(for: .milliseconds(200))
        #expect(store.progressValue == 0.5)
    }

    @Test
    func send_importButtonTapped_fileImporterIsPresented() async {
        let store = ImageVise(.testDependencies())
        await store.send(.importButtonTapped)
        #expect(store.isPresentedFileImporter)
    }

    @Test
    func send_imageFileAppeared_thumbnailOfMatchingImageFileIsSet() async {
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
        await store.send(.imageFileAppeared(store.imageFiles[0].id))
        #expect(store.imageFiles[0].thumbnail === thumbnail)
    }

    @Test
    func send_imageFileAppeared_thumbnailIsAlreadyLoaded_imageIsNotDecodedAgain() async {
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
        await store.send(.imageFileAppeared(store.imageFiles[0].id))
        #expect(createCallCount.withLock(\.self) == 0)
    }

    @Test
    func send_imageFileAppeared_identifierIsUnknown_imageIsNotDecoded() async {
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
        await store.send(.imageFileAppeared(UUID()))
        #expect(createCallCount.withLock(\.self) == 0)
    }

    @Test
    func send_convertButtonTapped_originalIsReplacedByWebP() async {
        let writtenURLs = OSAllocatedUnfairLock<[URL]>(initialState: [])
        let removedURLs = OSAllocatedUnfairLock<[URL]>(initialState: [])
        let store = ImageVise(
            .testDependencies(
                dataClient: testDependency(of: DataClient.self) {
                    $0.write = { _, url in writtenURLs.withLock { $0.append(url) } }
                },
                fileManagerClient: testDependency(of: FileManagerClient.self) {
                    $0.removeItem = { url in removedURLs.withLock { $0.append(url) } }
                },
                nsImageClient: testDependency(of: NSImageClient.self) {
                    $0.contentsOf = { _ in NSImage(size: NSSize(width: 1, height: 1)) }
                    $0.cgImage = { _ in CGImage.dummy() }
                }
            ),
            imageFiles: [ImageFile(url: URL(filePath: "/Users/test/photo.jpg"), size: "1 KB")]
        )
        await store.send(.convertButtonTapped)
        #expect(writtenURLs.withLock(\.self) == [URL(filePath: "/Users/test/photo.webp")])
        #expect(removedURLs.withLock(\.self) == [URL(filePath: "/Users/test/photo.jpg")])
    }

    @Test
    func send_convertButtonTapped_listIsClearedAndProcessingEnds() async {
        let store = ImageVise(
            .testDependencies(
                nsImageClient: testDependency(of: NSImageClient.self) {
                    $0.contentsOf = { _ in NSImage(size: NSSize(width: 1, height: 1)) }
                    $0.cgImage = { _ in CGImage.dummy() }
                }
            ),
            imageFiles: [ImageFile(url: URL(filePath: "/Users/test/photo.jpg"), size: "1 KB")]
        )
        await store.send(.convertButtonTapped)
        #expect(store.imageFiles.isEmpty)
        #expect(!store.isProcessing)
    }

    @Test
    func send_fileImportCompleted_bookmarkIsSaved_imageFilesAreSortedByFilename() async {
        let store = ImageVise(.testDependencies(
            fileManagerClient: testDependency(of: FileManagerClient.self) {
                $0.attributesOfItem = { _ in [.size: UInt64(2048)] }
            },
            userDefaultsClient: savedBookmarkUserDefaultsClient()
        ))
        let urls = [
            URL(filePath: "/Users/test/b.png"),
            URL(filePath: "/Users/test/a.jpg"),
            URL(filePath: "/Users/test/note.txt"),
        ]
        await store.send(.fileImportCompleted(.success(urls)))
        #expect(store.imageFiles.map(\.filename) == ["a.jpg", "b.png"])
    }

    @Test
    func send_fileImportCompleted_bookmarkIsNotSaved_homePermissionIsPresented() async {
        let store = ImageVise(.testDependencies(
            fileManagerClient: testDependency(of: FileManagerClient.self) {
                $0.attributesOfItem = { _ in [.size: UInt64(2048)] }
            }
        ))
        await store.send(.fileImportCompleted(.success([URL(filePath: "/Users/test/a.jpg")])))
        #expect(store.homePermission != nil)
        #expect(store.imageFiles.isEmpty)
    }

    @Test
    func send_fileImportCompleted_failure_imageFilesAreLeftUntouched() async {
        let store = ImageVise(.testDependencies(userDefaultsClient: savedBookmarkUserDefaultsClient()))
        await store.send(.fileImportCompleted(.failure(URLError(.unknown))))
        #expect(store.imageFiles.isEmpty)
        #expect(store.homePermission == nil)
    }

    @Test
    func send_homePermissionButtonTapped_homePermissionIsPresented() async {
        let store = ImageVise(.testDependencies())
        await store.send(.homePermissionButtonTapped)
        #expect(store.homePermission != nil)
    }

    @Test
    func send_homePermission_closeButtonTapped_sheetIsDismissed() async {
        let store = ImageVise(
            .testDependencies(userDefaultsClient: savedBookmarkUserDefaultsClient()),
            homePermission: HomePermission(.testDependencies())
        )
        await store.send(.homePermission(.closeButtonTapped))
        #expect(store.homePermission == nil)
        #expect(store.bookmarkState == .saved)
    }

    @Test
    func send_homePermission_setUpLaterButtonTapped_sheetIsDismissed() async {
        let store = ImageVise(
            .testDependencies(),
            homePermission: HomePermission(.testDependencies())
        )
        await store.send(.homePermission(.setUpLaterButtonTapped))
        #expect(store.homePermission == nil)
        #expect(store.bookmarkState == .notSaved)
    }

    @Test
    func send_homePermission_otherAction_sheetStaysPresented() async {
        let store = ImageVise(
            .testDependencies(),
            homePermission: HomePermission(.testDependencies())
        )
        await store.send(.homePermission(.grantPermissionButtonTapped))
        #expect(store.homePermission != nil)
    }
}
