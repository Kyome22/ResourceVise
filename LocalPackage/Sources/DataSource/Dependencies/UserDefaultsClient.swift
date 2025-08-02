/*
 UserDefaultsClient.swift
 DataSource

 Created by Takuto Nakamura on 2025/08/02.
 
*/

import Foundation

public struct UserDefaultsClient: DependencyClient {
    var object: @Sendable (String) -> Any?
    var removeObject: @Sendable (String) -> Void
    var data: @Sendable (String) -> Data?
    var setData: @Sendable (Data?, String) -> Void
    var bool: @Sendable (String) -> Bool
    var setBool: @Sendable (Bool, String) -> Void
    var removePersistentDomain: @Sendable (String) -> Void
    var persistentDomain: @Sendable (String) -> [String : Any]?

    public static let liveValue = Self(
        object: { UserDefaults.standard.object(forKey: $0) },
        removeObject: { UserDefaults.standard.removeObject(forKey: $0) },
        data: { UserDefaults.standard.data(forKey: $0) },
        setData: { UserDefaults.standard.set($0, forKey: $1) },
        bool: { UserDefaults.standard.bool(forKey: $0) },
        setBool: { UserDefaults.standard.set($0, forKey: $1) },
        removePersistentDomain: { UserDefaults.standard.removePersistentDomain(forName: $0) },
        persistentDomain: { UserDefaults.standard.persistentDomain(forName: $0) }
    )

    public static let testValue = Self(
        object: { _ in nil },
        removeObject: { _ in },
        data: { _ in nil },
        setData: { _, _ in },
        bool: { _ in false },
        setBool: { _, _ in },
        removePersistentDomain: { _ in },
        persistentDomain: { _ in nil }
    )
}

extension UserDefaults: @retroactive @unchecked Sendable {}
