//
//  EditorView.swift
//  Inklume
//
//  Created by Tufan Cakir on 03.10.26.
//

import PencilKit
import PhotosUI
import SwiftUI
import UIKit

struct EditorView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var editor: EditorViewModel
    @State private var photoItem: PhotosPickerItem?

    init(project: ArtProject) {
        _editor = State(initialValue: EditorViewModel(project: project))
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                NavigationStack {
                    editorDetail
                }
            } else {
                NavigationSplitView {
                    LayerPanel(editor: editor)
                        .navigationTitle("Layers")
                        .navigationSplitViewColumnWidth(
                            min: 220,
                            ideal: 260,
                            max: 320
                        )
                } detail: {
                    editorDetail
                }
            }
        }
        .task(id: photoItem) {
            guard
                let data = try? await photoItem?.loadTransferable(
                    type: Data.self
                )
            else { return }
            editor.addLayer(kind: .referenceImage, data: data)
            photoItem = nil
        }
    }

    private var editorDetail: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                CanvasToolbar(editor: editor, photoItem: $photoItem)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            }
            Divider()
            canvasWorkspace
        }
        .navigationTitle(editor.project.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Projects", systemImage: "chevron.backward") {
                    Task {
                        await appModel.save(editor.project)
                        dismiss()
                    }
                }
                .accessibilityIdentifier("projectsButton")
            }
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Layers", systemImage: "square.3.layers.3d") {
                    editor.showsLayers = true
                }
                .accessibilityIdentifier("layersButton")

                Button("Timeline", systemImage: "timeline.selection") {
                    editor.showsTimeline = true
                }
                .accessibilityIdentifier("timelineButton")

                Menu("More", systemImage: "ellipsis.circle") {
                    Button("Inspector", systemImage: "sidebar.right") {
                        editor.showsInspector.toggle()
                    }
                    Button("Save", systemImage: "square.and.arrow.down") {
                        Task { await appModel.save(editor.project) }
                    }
                }
            }
        }
        .inspector(isPresented: $editor.showsInspector) {
            InspectorPanel(editor: editor)
        }
        .sheet(isPresented: $editor.showsLayers) {
            LayerManagerSheet(editor: editor)
        }
        .sheet(isPresented: $editor.showsTimeline) {
            TimelineEditorSheet(editor: editor)
        }
    }

    private var canvasWorkspace: some View {
        GeometryReader { proxy in
            let available = CGSize(
                width: max(proxy.size.width - 48, 1),
                height: max(proxy.size.height - 48, 1)
            )
            let canvas = CGSize(
                width: editor.project.canvas.width,
                height: editor.project.canvas.height
            )
            let scale = min(
                available.width / max(canvas.width, 1),
                available.height / max(canvas.height, 1)
            )
            let displaySize = CGSize(
                width: canvas.width * scale,
                height: canvas.height * scale
            )

            ScrollView([.horizontal, .vertical]) {
                ZStack {
                    Color.clear
                    canvasContent
                        .frame(
                            width: displaySize.width,
                            height: displaySize.height
                        )
                        .clipShape(.rect)
                        .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
                        .padding(24)
                }
                .frame(minWidth: proxy.size.width, minHeight: proxy.size.height)
            }
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }

    private var canvasContent: some View {
        ZStack {
            if editor.project.canvas.isTransparent {
                CheckerboardView()
            } else {
                Color.white
            }

            ForEach(editor.project.layers) { layer in
                let presentedLayer = editor.presentationLayer(for: layer)
                if presentedLayer.isVisible {
                    layerContent(presentedLayer)
                        .modifier(
                            LayerSceneModifier(
                                layer: presentedLayer,
                                camera: editor.camera
                            )
                        )
                        .allowsHitTesting(false)
                }
            }

            if let selectedLayer = editor.selectedLayer {
                let layer = editor.presentationLayer(for: selectedLayer)
                if layer.kind == .drawing, layer.isVisible {
                    PencilCanvasView(
                        drawingData: drawingBinding,
                        tool: editor.selectedTool,
                        color: UIColor(editor.color),
                        width: editor.brushSize,
                        opacity: editor.opacity,
                        isLocked: layer.isLocked
                    )
                    .modifier(
                        LayerSceneModifier(layer: layer, camera: editor.camera)
                    )
                }
            }

            GridOverlay(
                configuration: editor.project.canvas.grid,
                canvasSize: CGSize(
                    width: editor.project.canvas.width,
                    height: editor.project.canvas.height
                )
            )
        }
        .aspectRatio(
            CGFloat(editor.project.canvas.width)
                / CGFloat(editor.project.canvas.height),
            contentMode: .fit
        )
        .accessibilityLabel("Drawing canvas")
    }

    @ViewBuilder
    private func layerContent(_ layer: ArtLayer) -> some View {
        if layer.id != editor.selectedLayerID,
            layer.kind == .drawing,
            let data = layer.contentData,
            let drawing = try? PKDrawing(data: data)
        {
            Image(uiImage: drawing.image(from: drawing.bounds, scale: 1))
                .resizable()
                .scaledToFit()
        } else if layer.kind == .importedImage || layer.kind == .referenceImage,
            let data = layer.contentData,
            let image = UIImage(data: data)
        {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        }
    }

    private var drawingBinding: Binding<Data?> {
        Binding(
            get: { editor.selectedLayer?.contentData },
            set: { data in
                guard let data else { return }
                editor.storeDrawing(data)
            }
        )
    }
}

private struct LayerSceneModifier: ViewModifier {
    let layer: ArtLayer
    let camera: CanvasCamera

    func body(content: Content) -> some View {
        let depth = layer.depthSettings ?? .standard
        let depthScale = max(
            0.15,
            1 + depth.depth / max(camera.perspectiveDistance, 100)
        )
        let cameraOffsetX = layer.transform.x - camera.x * depth.parallax
        let cameraOffsetY = layer.transform.y - camera.y * depth.parallax

        content
            .opacity(layer.opacity)
            .scaleEffect(
                x: layer.transform.scaleX * camera.zoom * depthScale,
                y: layer.transform.scaleY * camera.zoom * depthScale
            )
            .rotationEffect(.degrees(layer.transform.rotationDegrees))
            .rotation3DEffect(
                .degrees(depth.tiltXDegrees),
                axis: (x: 1, y: 0, z: 0),
                perspective: camera.perspective
            )
            .rotation3DEffect(
                .degrees(depth.tiltYDegrees),
                axis: (x: 0, y: 1, z: 0),
                perspective: camera.perspective
            )
            .offset(x: cameraOffsetX, y: cameraOffsetY)
    }
}
