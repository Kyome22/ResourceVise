/*
 ImageViseActionWrapper.swift
 Model

 Created by Takuto Nakamura on 2026/05/15.
 
*/

public struct ImageViseActionWrapper: Sendable {
    var send: @MainActor @Sendable (ImageVise.Action) async -> Void

    public init(send: @Sendable @MainActor @escaping (ImageVise.Action) async -> Void) {
        self.send = send
    }

    @MainActor public func callAsFunction(_ action: ImageVise.Action) async {
        await send(action)
    }
}
