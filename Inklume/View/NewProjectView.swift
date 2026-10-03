//
//  NewProjectView.swift
//  Inklume
//
//  Created by Tufan Cakir on 03.10.26.
//

import SwiftUI

struct NewProjectView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = "Untitled"
    @State private var selectedTemplateID = "blank"
    @State private var configuration = CanvasConfiguration.standard

    private var selectedTemplate: TemplateDefinition? {
        appModel.templates.first { $0.id == selectedTemplateID }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Template") {
                    Picker("Template", selection: $selectedTemplateID) {
                        ForEach(appModel.templates) { template in
                            Label(
                                template.name,
                                systemImage: template.symbolName
                            )
                            .tag(template.id)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section("Canvas") {
                    TextField("Project Name", text: $name)
                    LabeledContent("Width") {
                        TextField(
                            "Width",
                            value: $configuration.width,
                            format: .number
                        )
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Height") {
                        TextField(
                            "Height",
                            value: $configuration.height,
                            format: .number
                        )
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                    }
                    Picker("Orientation", selection: $configuration.orientation)
                    {
                        ForEach(CanvasOrientation.allCases) { orientation in
                            Text(orientation.rawValue.capitalized).tag(
                                orientation
                            )
                        }
                    }
                    Toggle(
                        "Transparent Background",
                        isOn: $configuration.isTransparent
                    )
                }

                Section("Grid") {
                    Toggle("Show Grid", isOn: $configuration.grid.isVisible)
                    Stepper(
                        "Cell Width: \(configuration.grid.cellWidth)",
                        value: $configuration.grid.cellWidth,
                        in: 1...1024
                    )
                    Stepper(
                        "Cell Height: \(configuration.grid.cellHeight)",
                        value: $configuration.grid.cellHeight,
                        in: 1...1024
                    )
                    Toggle(
                        "Snap to Grid",
                        isOn: $configuration.grid.isSnappingEnabled
                    )
                }

                if selectedTemplate?.frameConfiguration != nil {
                    Section("Frames & Tiles") {
                        numericField(
                            "Frame Width",
                            value: $configuration.frames.frameWidth
                        )
                        numericField(
                            "Frame Height",
                            value: $configuration.frames.frameHeight
                        )
                        numericField(
                            "Columns",
                            value: $configuration.frames.columns
                        )
                        numericField("Rows", value: $configuration.frames.rows)
                        numericField(
                            "Horizontal Spacing",
                            value: $configuration.frames.horizontalSpacing
                        )
                        numericField(
                            "Vertical Spacing",
                            value: $configuration.frames.verticalSpacing
                        )
                    }
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let bounded = CanvasConfiguration(
                            width: min(max(configuration.width, 1), 16_384),
                            height: min(max(configuration.height, 1), 16_384),
                            backgroundHex: configuration.backgroundHex,
                            isTransparent: configuration.isTransparent,
                            orientation: configuration.orientation,
                            grid: configuration.grid,
                            frames: configuration.frames
                        )
                        Task {
                            await appModel.createProject(
                                name: name,
                                template: selectedTemplate,
                                configuration: bounded
                            )
                        }
                    }
                    .disabled(
                        name.trimmingCharacters(in: .whitespacesAndNewlines)
                            .isEmpty
                    )
                }
            }
            .onChange(of: selectedTemplateID) {
                guard let template = selectedTemplate else { return }
                configuration.width = template.width
                configuration.height = template.height
                configuration.isTransparent = template.transparentByDefault
                configuration.frames =
                    template.frameConfiguration ?? FrameConfiguration()
            }
        }
    }

    private func numericField(_ title: LocalizedStringKey, value: Binding<Int>)
        -> some View
    {
        LabeledContent(title) {
            TextField(title, value: value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
        }
    }
}
