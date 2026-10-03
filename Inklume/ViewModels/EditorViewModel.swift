//
//  EditorViewModel.swift
//  Inklume
//
//  Created by Tufan Cakir on 03.10.26.
//

import Foundation
import Observation
import PencilKit
import SwiftUI

@MainActor
@Observable
final class EditorViewModel {
    var project: ArtProject
    var selectedLayerID: UUID?
    var selectedTool: DrawingTool = .pen
    var color = Color.black
    var brushSize = 8.0
    var opacity = 1.0
    var showsInspector = false
    var showsGridSettings = false
    var showsTimeline = false
    var showsLayers = false
    var playhead = 0.0
    var isPlaying = false
    private(set) var completedLoops = 0

    init(project: ArtProject) {
        self.project = project
        selectedLayerID = project.layers.last?.id
    }

    var selectedLayer: ArtLayer? {
        project.layers.first { $0.id == selectedLayerID }
    }

    var camera: CanvasCamera {
        project.camera ?? .standard
    }

    var selectedDepthSettings: LayerDepthSettings {
        selectedLayer?.depthSettings ?? .standard
    }

    func updateCamera(_ update: (inout CanvasCamera) -> Void) {
        var camera = project.camera ?? .standard
        update(&camera)
        project.camera = camera
        markChanged()
    }

    func updateSelectedDepth(_ update: (inout LayerDepthSettings) -> Void) {
        updateSelectedLayer { layer in
            var settings = layer.depthSettings ?? .standard
            update(&settings)
            layer.depthSettings = settings
        }
    }

    func addLayer(kind: LayerKind = .drawing, data: Data? = nil) {
        let count = project.layers.count + 1
        let layer = ArtLayer(
            name: kind == .referenceImage
                ? "Reference \(count)" : "Layer \(count)",
            kind: kind,
            contentData: data
        )
        project.layers.append(layer)
        selectedLayerID = layer.id
        markChanged()
    }

    func deleteSelectedLayer() {
        guard project.layers.count > 1, let id = selectedLayerID else { return }
        project.layers.removeAll { $0.id == id }
        project.timeline.keyframes.removeAll { $0.layerID == id }
        selectedLayerID = project.layers.last?.id
        markChanged()
    }

    func duplicateSelectedLayer() {
        guard var layer = selectedLayer else { return }
        layer.id = UUID()
        layer.name += " Copy"
        project.layers.append(layer)
        selectedLayerID = layer.id
        markChanged()
    }

    func moveLayersInVisualOrder(from source: IndexSet, to destination: Int) {
        var visualOrder = Array(project.layers.reversed())
        visualOrder.move(fromOffsets: source, toOffset: destination)
        project.layers = visualOrder.reversed()
        markChanged()
    }

    func updateSelectedLayer(_ update: (inout ArtLayer) -> Void) {
        guard let id = selectedLayerID,
            let index = project.layers.firstIndex(where: { $0.id == id })
        else { return }
        update(&project.layers[index])
        markChanged()
    }

    func storeDrawing(_ data: Data) {
        updateSelectedLayer { layer in
            guard layer.kind == .drawing else { return }
            layer.contentData = data
        }
    }

    func addKeyframe() {
        guard let layer = selectedLayer else { return }
        project.timeline.keyframes.removeAll {
            $0.layerID == layer.id && abs($0.time - playhead) < 0.0001
        }
        project.timeline.keyframes.append(
            LayerKeyframe(
                time: playhead,
                layerID: layer.id,
                transform: layer.transform,
                opacity: layer.opacity,
                isVisible: layer.isVisible,
                interpolation: .linear,
                depthSettings: layer.depthSettings
            )
        )
        markChanged()
    }

    func removeKeyframe(_ id: UUID) {
        project.timeline.keyframes.removeAll { $0.id == id }
        markChanged()
    }

    func startPlayback() {
        guard project.timeline.duration > 0 else { return }
        if playhead >= project.timeline.duration {
            playhead = 0
        }
        completedLoops = 0
        isPlaying = true
    }

    func pausePlayback() {
        isPlaying = false
    }

    func stopPlayback() {
        isPlaying = false
        completedLoops = 0
        playhead = 0
    }

    func advancePlayback(by interval: TimeInterval) {
        guard isPlaying else { return }
        let duration = max(project.timeline.duration, 0.01)
        let nextTime = playhead + interval
        guard nextTime >= duration else {
            playhead = nextTime
            return
        }

        completedLoops += 1
        if project.timeline.loopsInfinitely
            || completedLoops < max(project.timeline.loopCount, 1)
        {
            playhead = nextTime.truncatingRemainder(dividingBy: duration)
        } else {
            playhead = duration
            isPlaying = false
        }
    }

    func presentationLayer(for layer: ArtLayer) -> ArtLayer {
        let keyframes = project.timeline.keyframes
            .filter { $0.layerID == layer.id }
            .sorted { $0.time < $1.time }
        guard let first = keyframes.first else { return layer }

        if playhead <= first.time {
            return applying(first, to: layer)
        }
        guard let last = keyframes.last, playhead < last.time else {
            return applying(keyframes.last ?? first, to: layer)
        }

        guard
            let upperIndex = keyframes.firstIndex(where: { $0.time >= playhead }
            ),
            upperIndex > 0
        else {
            return layer
        }
        let lower = keyframes[upperIndex - 1]
        let upper = keyframes[upperIndex]
        let progress = AnimationEngine.progress(
            at: playhead,
            from: lower.time,
            to: upper.time,
            mode: lower.interpolation
        )

        var result = layer
        result.transform.x = AnimationEngine.interpolate(
            lower.transform.x,
            upper.transform.x,
            progress: progress
        )
        result.transform.y = AnimationEngine.interpolate(
            lower.transform.y,
            upper.transform.y,
            progress: progress
        )
        result.transform.scaleX = AnimationEngine.interpolate(
            lower.transform.scaleX,
            upper.transform.scaleX,
            progress: progress
        )
        result.transform.scaleY = AnimationEngine.interpolate(
            lower.transform.scaleY,
            upper.transform.scaleY,
            progress: progress
        )
        result.transform.rotationDegrees = AnimationEngine.interpolate(
            lower.transform.rotationDegrees,
            upper.transform.rotationDegrees,
            progress: progress
        )
        result.opacity = AnimationEngine.interpolate(
            lower.opacity,
            upper.opacity,
            progress: progress
        )
        result.isVisible = progress < 1 ? lower.isVisible : upper.isVisible

        let lowerDepth = lower.depthSettings ?? layer.depthSettings ?? .standard
        let upperDepth = upper.depthSettings ?? layer.depthSettings ?? .standard
        result.depthSettings = LayerDepthSettings(
            depth: AnimationEngine.interpolate(
                lowerDepth.depth,
                upperDepth.depth,
                progress: progress
            ),
            parallax: AnimationEngine.interpolate(
                lowerDepth.parallax,
                upperDepth.parallax,
                progress: progress
            ),
            tiltXDegrees: AnimationEngine.interpolate(
                lowerDepth.tiltXDegrees,
                upperDepth.tiltXDegrees,
                progress: progress
            ),
            tiltYDegrees: AnimationEngine.interpolate(
                lowerDepth.tiltYDegrees,
                upperDepth.tiltYDegrees,
                progress: progress
            )
        )
        return result
    }

    func markChanged() {
        project.modifiedAt = Date()
    }

    private func applying(_ keyframe: LayerKeyframe, to layer: ArtLayer)
        -> ArtLayer
    {
        var result = layer
        result.transform = keyframe.transform
        result.opacity = keyframe.opacity
        result.isVisible = keyframe.isVisible
        result.depthSettings = keyframe.depthSettings ?? layer.depthSettings
        return result
    }
}
