/*
 CGImage+Extension.swift
 Model

 Created by Takuto Nakamura on 2025/08/02.
 
*/

import CoreGraphics

extension CGImage {
    func resize(ratio: CGFloat) -> CGImage? {
        let newWidth = Int(ratio * CGFloat(width))
        let newHeight = Int(ratio * CGFloat(height))
        guard let colorSpace else { return nil }
        let context = CGContext(
            data: nil,
            width: newWidth,
            height: newHeight,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: .zero,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        guard let context else { return nil }
        context.interpolationQuality = .high
        context.draw(self, in: CGRect(x: .zero, y: .zero, width: newWidth, height: newHeight))
        return context.makeImage()
    }
}
