//
//  ToolModels.swift
//  Inklume
//
//  Created by Tufan Cakir on 03.10.26.
//

import Foundation
import SwiftUI

enum DrawingTool: String, CaseIterable, Identifiable {
    case pencil, pen, marker, brush, eraser, selection, fill
    var id: Self { self }

    var symbolName: String {
        switch self {
        case .pencil: "pencil"
        case .pen: "pencil.tip"
        case .marker: "highlighter"
        case .brush: "paintbrush"
        case .eraser: "eraser"
        case .selection: "lasso"
        case .fill: "paintbrush.pointed"
        }
    }
}

enum PaintStyle: Equatable {
    case solid
    case linearGradient
    case radialGradient
}

struct RGBAColor: Codable, Hashable, Sendable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    static let black = RGBAColor(red: 0, green: 0, blue: 0, alpha: 1)

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}
