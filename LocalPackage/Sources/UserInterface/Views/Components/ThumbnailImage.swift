/*
 ThumbnailImage.swift
 UserInterface

 Created by Takuto Nakamura on 2026/08/02.

*/

import CoreGraphics
import SwiftUI

struct ThumbnailImage: View {
    let thumbnail: CGImage?

    var body: some View {
        Group {
            if let thumbnail {
                Image(decorative: thumbnail, scale: 2)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "questionmark.square.dashed")
            }
        }
        .frame(width: 25, height: 25)
    }
}
