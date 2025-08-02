/*
 AppDelegate.swift
 Model

 Created by Takuto Nakamura on 2024/11/13.
 
*/

import AppKit
import DataSource

public final class AppDelegate: NSObject, NSApplicationDelegate {
    public let appDependencies = AppDependencies.shared

    public func applicationDidFinishLaunching(_ notification: Notification) {
        let logService = LogService(appDependencies)
        logService.bootstrap()
        logService.notice(.launchApp)

        ImageConvertService(appDependencies).setHomeDirectory()
    }

    public func applicationWillTerminate(_ notification: Notification) {
        let bookmarkRepository = BookmarkRepository(appDependencies.urlClient, appDependencies.userDefaultsClient)
        if bookmarkRepository.bookmarkState == .saved {
            bookmarkRepository.disable()
        }
    }

    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
