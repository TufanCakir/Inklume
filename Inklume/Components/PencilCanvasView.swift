//
//  PencilCanvasView.swift
//  Inklume
//
//  Created by Tufan Cakir on 03.10.26.
//

import PencilKit
import SwiftUI
import UIKit

struct PencilCanvasView: UIViewRepresentable {
    @Binding var drawingData: Data?
    let tool: DrawingTool
    let color: UIColor
    let width: CGFloat
    let opacity: CGFloat
    let isLocked: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(drawingData: $drawingData)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.delegate = context.coordinator
        canvas.drawingPolicy = .anyInput
        canvas.maximumZoomScale = 8
        canvas.minimumZoomScale = 0.25
        canvas.bouncesZoom = true
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        canvas.isUserInteractionEnabled = !isLocked
        canvas.tool = pencilKitTool
        if let drawingData,
            context.coordinator.lastLoadedData != drawingData,
            let drawing = try? PKDrawing(data: drawingData)
        {
            context.coordinator.isApplyingDrawing = true
            canvas.drawing = drawing
            context.coordinator.lastLoadedData = drawingData
            context.coordinator.isApplyingDrawing = false
        } else if drawingData == nil, context.coordinator.lastLoadedData != nil
        {
            context.coordinator.isApplyingDrawing = true
            canvas.drawing = PKDrawing()
            context.coordinator.lastLoadedData = nil
            context.coordinator.isApplyingDrawing = false
        }
    }

    private var pencilKitTool: PKTool {
        let resolvedColor = color.withAlphaComponent(opacity)
        switch tool {
        case .pencil:
            return PKInkingTool(.pencil, color: resolvedColor, width: width)
        case .pen, .brush:
            return PKInkingTool(.pen, color: resolvedColor, width: width)
        case .marker:
            return PKInkingTool(.marker, color: resolvedColor, width: width)
        case .eraser:
            return PKEraserTool(.vector)
        case .selection:
            return PKLassoTool()
        case .fill:
            return PKInkingTool(.pen, color: resolvedColor, width: width)
        }
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var drawingData: Data?
        var lastLoadedData: Data?
        var isApplyingDrawing = false

        init(drawingData: Binding<Data?>) {
            _drawingData = drawingData
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            guard !isApplyingDrawing else { return }
            let data = canvasView.drawing.dataRepresentation()
            lastLoadedData = data
            drawingData = data
        }
    }
}
