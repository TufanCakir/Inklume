//
//  AnimationEngine.swift
//  Inklume
//
//  Created by Tufan Cakir on 03.10.26.
//

import Foundation

enum AnimationEngine {
    static func progress(
        at time: TimeInterval,
        from start: TimeInterval,
        to end: TimeInterval,
        mode: InterpolationMode
    ) -> Double {
        guard end > start else { return 1 }
        let value = min(max((time - start) / (end - start), 0), 1)
        switch mode {
        case .linear: return value
        case .easeIn: return value * value
        case .easeOut: return 1 - pow(1 - value, 2)
        case .easeInOut:
            return value < 0.5
                ? 2 * value * value : 1 - pow(-2 * value + 2, 2) / 2
        case .hold: return value < 1 ? 0 : 1
        }
    }

    static func interpolate(_ start: Double, _ end: Double, progress: Double)
        -> Double
    {
        start + (end - start) * progress
    }
}

struct SpriteSheetLayout: Equatable, Sendable {
    let pixelWidth: Int
    let pixelHeight: Int

    init(configuration: FrameConfiguration) {
        pixelWidth =
            configuration.padding * 2
            + configuration.columns * configuration.frameWidth
            + max(0, configuration.columns - 1)
            * configuration.horizontalSpacing
        pixelHeight =
            configuration.padding * 2
            + configuration.rows * configuration.frameHeight
            + max(0, configuration.rows - 1) * configuration.verticalSpacing
    }
}
