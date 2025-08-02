/*
 BookmarkSstate+Extension.swift
 UserInterface

 Created by Takuto Nakamura on 2025/08/02.
 
*/

import DataSource
import SwiftUI

extension BookmarkState {
    var label: String {
        switch self {
        case .notSaved:
            String(localized: "permissionIsNotGranted", bundle: .module)
        case .saved:
            String(localized: "permissionIsGranted", bundle: .module)
        }
    }

    var imageName: String {
        switch self {
        case .notSaved:
            "lock.shield.fill"
        case .saved:
            "checkmark.shield.fill"
        }
    }

    var imageColor: Color {
        switch self {
        case .notSaved:
            Color.red
        case .saved:
            Color.green
        }
    }
}
