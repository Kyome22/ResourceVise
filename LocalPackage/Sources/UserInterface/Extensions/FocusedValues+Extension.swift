/*
 FocusedValues+Extension.swift
 UserInterface

 Created by Takuto Nakamura on 2024/11/30.
 
*/

import Model
import SwiftUI

struct ImageViseSendAction {
    var send: @MainActor @Sendable (ImageVise.Action) async -> Void

    @MainActor
    func callAsFunction(_ action: ImageVise.Action) async {
        await send(action)
    }
}

private struct ImageViseSendActionKey: FocusedValueKey {
    typealias Value = ImageViseSendAction
}

private struct DisableToConvertKey: FocusedValueKey {
    typealias Value = Bool
}

extension FocusedValues {
    var imageViseSend: ImageViseSendAction? {
        get { self[ImageViseSendActionKey.self] }
        set { self[ImageViseSendActionKey.self] = newValue }
    }

    var disableToConvert: Bool? {
        get { self[DisableToConvertKey.self] }
        set { self[DisableToConvertKey.self] = newValue }
    }
}
