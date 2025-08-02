/*
 URL+Extension.swift
 Model

 Created by Takuto Nakamura on 2025/08/02.
 
*/

import Foundation

extension URL {
    func compare(with url: URL) -> Bool {
        self.path().lowercased() == url.path().lowercased()
    }
}
