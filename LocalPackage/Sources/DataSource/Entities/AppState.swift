/*
 AppState.swift
 LocalPackage

 Created by Takuto Nakamura on 2025/07/27.
 
*/

import Combine

public struct AppState: Sendable {
    public var hasAlreadyBootstrap = false
    public let progressSubject = PassthroughSubject<Double, Never>()
}

extension CurrentValueSubject: @retroactive @unchecked Sendable where Failure == Never, Output : Sendable {}
extension PassthroughSubject: @retroactive @unchecked Sendable where Failure == Never, Output : Sendable {}
extension AsyncPublisher: @retroactive @unchecked Sendable {}
