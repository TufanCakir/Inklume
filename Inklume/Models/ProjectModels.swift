//
//  ProjectModels.swift
//  Inklume
//
//  Created by Tufan Cakir on 03.10.26.
//

import Foundation

nonisolated enum CanvasOrientation: String, Codable, CaseIterable, Identifiable,
    Sendable
{
    case portrait, landscape
    var id: Self { self }
}

nonisolated enum LayerKind: String, Codable, CaseIterable, Sendable {
    case drawing, importedImage, referenceImage, background, text, shape
}

nonisolated struct CanvasConfiguration: Codable, Hashable, Sendable {
    var width: Int
    var height: Int
    var backgroundHex: String
    var isTransparent: Bool
    var orientation: CanvasOrientation
    var grid: GridConfiguration
    var frames: FrameConfiguration

    static let standard = CanvasConfiguration(
        width: 2048,
        height: 2048,
        backgroundHex: "#FFFFFF",
        isTransparent: true,
        orientation: .portrait,
        grid: .init(),
        frames: .init()
    )
}

nonisolated struct GridConfiguration: Codable, Hashable, Sendable {
    var isVisible = false
    var cellWidth = 32
    var cellHeight = 32
    var spacing = 0
    var opacity = 0.3
    var subdivisions = 1
    var isSnappingEnabled = false
}

nonisolated struct FrameConfiguration: Codable, Hashable, Sendable {
    var frameWidth = 64
    var frameHeight = 64
    var columns = 4
    var rows = 1
    var horizontalSpacing = 0
    var verticalSpacing = 0
    var padding = 0
}

nonisolated struct LayerTransform: Codable, Hashable, Sendable {
    var x = 0.0
    var y = 0.0
    var scaleX = 1.0
    var scaleY = 1.0
    var rotationDegrees = 0.0
}

nonisolated struct LayerDepthSettings: Codable, Hashable, Sendable {
    var depth = 0.0
    var parallax = 1.0
    var tiltXDegrees = 0.0
    var tiltYDegrees = 0.0

    static let standard = LayerDepthSettings()
}

nonisolated struct CanvasCamera: Codable, Hashable, Sendable {
    var x = 0.0
    var y = 0.0
    var zoom = 1.0
    var perspective = 0.6
    var perspectiveDistance = 1000.0

    static let standard = CanvasCamera()
}

nonisolated struct ArtLayer: Identifiable, Codable, Hashable, Sendable {
    var id = UUID()
    var name: String
    var isVisible = true
    var opacity = 1.0
    var isLocked = false
    var kind: LayerKind
    var transform = LayerTransform()
    var contentFileName: String?
    var contentData: Data?
    var depthSettings: LayerDepthSettings? = nil
}

nonisolated enum InterpolationMode: String, Codable, CaseIterable, Sendable {
    case linear, easeIn, easeOut, easeInOut, hold
}

nonisolated struct LayerKeyframe: Identifiable, Codable, Hashable, Sendable {
    var id = UUID()
    var time: TimeInterval
    var layerID: UUID
    var transform: LayerTransform
    var opacity: Double
    var isVisible: Bool
    var interpolation: InterpolationMode
    var depthSettings: LayerDepthSettings? = nil
}

nonisolated struct TimelineConfiguration: Codable, Hashable, Sendable {
    var duration = 2.0
    var framesPerSecond = 12
    var loopCount = 1
    var loopsInfinitely = true
    var keyframes: [LayerKeyframe] = []
}

nonisolated struct AnimationFrame: Identifiable, Codable, Hashable, Sendable {
    var id = UUID()
    var duration = 1.0 / 12.0
    var layerIDs: [UUID]
}

nonisolated struct ArtProject: Identifiable, Codable, Hashable, Sendable {
    var id = UUID()
    var name: String
    var createdAt = Date()
    var modifiedAt = Date()
    var templateID: String?
    var canvas: CanvasConfiguration
    var layers: [ArtLayer]
    var timeline = TimelineConfiguration()
    var animationFrames: [AnimationFrame] = []
    var camera: CanvasCamera? = nil

    static func blank(
        name: String = "Untitled",
        canvas: CanvasConfiguration = .standard,
        templateID: String? = nil
    ) -> ArtProject {
        ArtProject(
            name: name,
            templateID: templateID,
            canvas: canvas,
            layers: [ArtLayer(name: "Drawing", kind: .drawing)]
        )
    }
}

nonisolated struct TemplateDefinition: Identifiable, Codable, Hashable, Sendable
{
    var id: String
    var name: String
    var category: String
    var symbolName: String
    var width: Int
    var height: Int
    var transparentByDefault: Bool
    var frameConfiguration: FrameConfiguration?
    var tags: [String]
}

nonisolated struct TemplateCatalog: Codable, Sendable {
    var version: Int
    var templates: [TemplateDefinition]
}
