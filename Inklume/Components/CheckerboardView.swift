//
//  CheckerboardView.swift
//  Inklume
//
//  Created by Tufan Cakir on 03.10.26.
//

import SwiftUI

struct CheckerboardView: View {
    var squareSize: CGFloat = 14

    var body: some View {
        Canvas { context, size in
            let columns = Int(ceil(size.width / squareSize))
            let rows = Int(ceil(size.height / squareSize))
            for row in 0..<rows {
                for column in 0..<columns where (row + column).isMultiple(of: 2)
                {
                    context.fill(
                        Path(
                            CGRect(
                                x: CGFloat(column) * squareSize,
                                y: CGFloat(row) * squareSize,
                                width: squareSize,
                                height: squareSize
                            )
                        ),
                        with: .color(.secondary.opacity(0.12))
                    )
                }
            }
        }
        .background(.white)
        .accessibilityHidden(true)
    }
}

struct GridOverlay: View {
    let configuration: GridConfiguration
    let canvasSize: CGSize

    var body: some View {
        Canvas { context, size in
            guard configuration.isVisible else { return }
            let scaleX = size.width / max(canvasSize.width, 1)
            let scaleY = size.height / max(canvasSize.height, 1)
            let stepX = max(
                CGFloat(configuration.cellWidth + configuration.spacing)
                    * scaleX,
                4
            )
            let stepY = max(
                CGFloat(configuration.cellHeight + configuration.spacing)
                    * scaleY,
                4
            )
            var path = Path()
            stride(from: 0, through: size.width, by: stepX).forEach {
                path.move(to: CGPoint(x: $0, y: 0))
                path.addLine(to: CGPoint(x: $0, y: size.height))
            }
            stride(from: 0, through: size.height, by: stepY).forEach {
                path.move(to: CGPoint(x: 0, y: $0))
                path.addLine(to: CGPoint(x: size.width, y: $0))
            }
            context.stroke(
                path,
                with: .color(.accentColor.opacity(configuration.opacity)),
                lineWidth: 0.5
            )
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
