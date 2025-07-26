/*
 FocusedValues+Extension.swift
 UserInterface

 Created by Takuto Nakamura on 2024/11/30.
 
*/

import Model
import SwiftUI

struct ImageViseSendAction {
    var send: @MainActor @Sendable (ImageVise.Action) -> Void

    @MainActor
    func callAsFunction(_ action: ImageVise.Action) {
        send(action)
    }
}

private struct ImageViseSendActionKey: FocusedValueKey {
    typealias Value = ImageViseSendAction
}

private struct DisableToExportKey: FocusedValueKey {
    typealias Value = Bool
}

extension FocusedValues {
    var imageViseSend: ImageViseSendAction? {
        get { self[ImageViseSendActionKey.self] }
        set { self[ImageViseSendActionKey.self] = newValue }
    }

    var disableToExport: Bool? {
        get { self[DisableToExportKey.self] }
        set { self[DisableToExportKey.self] = newValue }
    }
}
