//
//  EditorControls.swift
//  Inklume
//
//  Created by Tufan Cakir on 03.10.26.
//

import PhotosUI
import SwiftUI

struct CanvasToolbar: View {
    @Bindable var editor: EditorViewModel
    @Binding var photoItem: PhotosPickerItem?

    var body: some View {
        HStack(spacing: 6) {
            ForEach(DrawingTool.allCases) { tool in
                Button {
                    editor.selectedTool = tool
                } label: {
                    Image(systemName: tool.symbolName)
                        .frame(minWidth: 32, minHeight: 32)
                }
                .buttonStyle(.bordered)
                .tint(editor.selectedTool == tool ? .accentColor : .secondary)
                .accessibilityLabel(tool.rawValue.capitalized)
            }
            Divider().frame(height: 24)
            PhotosPicker(selection: $photoItem, matching: .images) {
                Label("Reference", systemImage: "photo.badge.plus")
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.bordered)
        }
        .controlSize(.small)
    }
}

struct LayerManagerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var editor: EditorViewModel

    var body: some View {
        NavigationStack {
            LayerPanel(editor: editor)
                .navigationTitle("Layers")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("layerManagerSheet")
    }
}

struct LayerPanel: View {
    @Bindable var editor: EditorViewModel
    @State private var confirmsDeletion = false

    var body: some View {
        List(selection: $editor.selectedLayerID) {
            Section {
                ForEach(Array(editor.project.layers.reversed())) { layer in
                    LayerRow(
                        layer: layer,
                        isSelected: layer.id == editor.selectedLayerID,
                        toggleVisibility: {
                            editor.selectedLayerID = layer.id
                            editor.updateSelectedLayer { $0.isVisible.toggle() }
                        },
                        toggleLock: {
                            editor.selectedLayerID = layer.id
                            editor.updateSelectedLayer { $0.isLocked.toggle() }
                        }
                    )
                    .tag(layer.id)
                    .contextMenu {
                        Button(
                            "Duplicate",
                            systemImage: "plus.square.on.square"
                        ) {
                            editor.selectedLayerID = layer.id
                            editor.duplicateSelectedLayer()
                        }
                        Button(
                            "Delete",
                            systemImage: "trash",
                            role: .destructive
                        ) {
                            editor.selectedLayerID = layer.id
                            confirmsDeletion = true
                        }
                    }
                }
                .onMove(perform: editor.moveLayersInVisualOrder)
            } header: {
                Label(
                    "Top layer first",
                    systemImage: "square.3.layers.3d.top.filled"
                )
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button("Add Drawing Layer", systemImage: "plus") {
                    editor.addLayer()
                }
                Button("Duplicate Layer", systemImage: "plus.square.on.square")
                {
                    editor.duplicateSelectedLayer()
                }
                .disabled(editor.selectedLayer == nil)
                Spacer()
                EditButton()
                Button("Delete Layer", systemImage: "trash", role: .destructive)
                {
                    confirmsDeletion = true
                }
                .disabled(editor.project.layers.count == 1)
            }
            .labelStyle(.iconOnly)
            .padding(8)
            .background(.bar)
        }
        .confirmationDialog(
            "Delete this layer?",
            isPresented: $confirmsDeletion,
            titleVisibility: .visible
        ) {
            Button("Delete Layer", role: .destructive) {
                editor.deleteSelectedLayer()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "Only the selected layer is deleted. Other layers remain unchanged."
            )
        }
    }
}

private struct LayerRow: View {
    let layer: ArtLayer
    let isSelected: Bool
    let toggleVisibility: () -> Void
    let toggleLock: () -> Void

    var body: some View {
        HStack {
            Button(action: toggleVisibility) {
                Image(systemName: layer.isVisible ? "eye" : "eye.slash")
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading) {
                Text(layer.name)
                Text(layer.kind.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: toggleLock) {
                Image(systemName: layer.isLocked ? "lock.fill" : "lock.open")
            }
            .buttonStyle(.plain)
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(layer.name), \(layer.kind.rawValue), \(layer.isVisible ? "visible" : "hidden")"
        )
    }
}

struct InspectorPanel: View {
    @Bindable var editor: EditorViewModel

    var body: some View {
        Form {
            Section("Brush") {
                ColorPicker(
                    "Color",
                    selection: $editor.color,
                    supportsOpacity: false
                )
                LabeledContent("Size") {
                    Slider(value: $editor.brushSize, in: 1...120)
                }
                LabeledContent("Opacity") {
                    Slider(value: $editor.opacity, in: 0.05...1)
                }
            }

            if editor.selectedLayer != nil {
                Section("Layer") {
                    TextField(
                        "Name",
                        text: Binding(
                            get: { editor.selectedLayer?.name ?? "" },
                            set: { value in
                                editor.updateSelectedLayer { $0.name = value }
                            }
                        )
                    )
                    Toggle(
                        "Visible",
                        isOn: Binding(
                            get: { editor.selectedLayer?.isVisible ?? false },
                            set: { value in
                                editor.updateSelectedLayer {
                                    $0.isVisible = value
                                }
                            }
                        )
                    )
                    Toggle(
                        "Locked",
                        isOn: Binding(
                            get: { editor.selectedLayer?.isLocked ?? false },
                            set: { value in
                                editor.updateSelectedLayer {
                                    $0.isLocked = value
                                }
                            }
                        )
                    )
                    LabeledContent("Layer Opacity") {
                        Slider(
                            value: Binding(
                                get: { editor.selectedLayer?.opacity ?? 1 },
                                set: { value in
                                    editor.updateSelectedLayer {
                                        $0.opacity = value
                                    }
                                }
                            ),
                            in: 0...1
                        )
                    }
                }

                Section("2.5D Layer") {
                    depthSlider(
                        "Depth",
                        value: Binding(
                            get: { editor.selectedDepthSettings.depth },
                            set: { value in
                                editor.updateSelectedDepth { $0.depth = value }
                            }
                        ),
                        range: -500...500
                    )
                    depthSlider(
                        "Parallax",
                        value: Binding(
                            get: { editor.selectedDepthSettings.parallax },
                            set: { value in
                                editor.updateSelectedDepth {
                                    $0.parallax = value
                                }
                            }
                        ),
                        range: 0...2
                    )
                    depthSlider(
                        "Tilt X",
                        value: Binding(
                            get: { editor.selectedDepthSettings.tiltXDegrees },
                            set: { value in
                                editor.updateSelectedDepth {
                                    $0.tiltXDegrees = value
                                }
                            }
                        ),
                        range: -60...60
                    )
                    depthSlider(
                        "Tilt Y",
                        value: Binding(
                            get: { editor.selectedDepthSettings.tiltYDegrees },
                            set: { value in
                                editor.updateSelectedDepth {
                                    $0.tiltYDegrees = value
                                }
                            }
                        ),
                        range: -60...60
                    )
                    Button(
                        "Reset Layer Depth",
                        systemImage: "arrow.counterclockwise"
                    ) {
                        editor.updateSelectedDepth { $0 = .standard }
                    }
                }
            }

            Section("2.5D Camera") {
                depthSlider(
                    "Camera X",
                    value: Binding(
                        get: { editor.camera.x },
                        set: { value in editor.updateCamera { $0.x = value } }
                    ),
                    range: -1000...1000
                )
                depthSlider(
                    "Camera Y",
                    value: Binding(
                        get: { editor.camera.y },
                        set: { value in editor.updateCamera { $0.y = value } }
                    ),
                    range: -1000...1000
                )
                depthSlider(
                    "Zoom",
                    value: Binding(
                        get: { editor.camera.zoom },
                        set: { value in editor.updateCamera { $0.zoom = value }
                        }
                    ),
                    range: 0.25...4
                )
                depthSlider(
                    "Perspective",
                    value: Binding(
                        get: { editor.camera.perspective },
                        set: { value in
                            editor.updateCamera { $0.perspective = value }
                        }
                    ),
                    range: 0.1...1
                )
                Button(
                    "Reset Camera",
                    systemImage: "camera.metering.center.weighted"
                ) {
                    editor.updateCamera { $0 = .standard }
                }
            }

            Section("Grid") {
                Toggle("Show Grid", isOn: $editor.project.canvas.grid.isVisible)
                Toggle(
                    "Snap",
                    isOn: $editor.project.canvas.grid.isSnappingEnabled
                )
                Stepper(
                    "Width: \(editor.project.canvas.grid.cellWidth)",
                    value: $editor.project.canvas.grid.cellWidth,
                    in: 1...1024
                )
                Stepper(
                    "Height: \(editor.project.canvas.grid.cellHeight)",
                    value: $editor.project.canvas.grid.cellHeight,
                    in: 1...1024
                )
            }
        }
        .inspectorColumnWidth(min: 260, ideal: 300, max: 380)
    }

    private func depthSlider(
        _ title: LocalizedStringKey,
        value: Binding<Double>,
        range: ClosedRange<Double>
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text(
                    value.wrappedValue,
                    format: .number.precision(.fractionLength(1))
                )
                .foregroundStyle(.secondary)
                .monospacedDigit()
            }
            Slider(value: value, in: range)
        }
    }
}
