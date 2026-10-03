//
//  StartView.swift
//  Inklume
//
//  Created by Tufan Cakir on 03.10.26.
//

import SwiftUI

struct StartView: View {
    @Environment(AppModel.self) private var appModel

    private let columns = [GridItem(.adaptive(minimum: 180), spacing: 16)]

    var body: some View {
        NavigationStack {
            ScrollView {
                if appModel.projects.isEmpty {
                    ContentUnavailableView {
                        Label("Create Something", systemImage: "paintpalette")
                    } description: {
                        Text("Start with a template or a custom canvas.")
                    } actions: {
                        Button("New Project", systemImage: "plus") {
                            appModel.isCreatingProject = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(minHeight: 420)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(appModel.projects) { project in
                            ProjectCard(project: project)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Inklume")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New Project", systemImage: "plus") {
                        appModel.isCreatingProject = true
                    }
                    .keyboardShortcut("n", modifiers: .command)
                }
            }
            .sheet(isPresented: Bindable(appModel).isCreatingProject) {
                NewProjectView()
            }
            .fullScreenCover(item: Bindable(appModel).selectedProject) {
                project in
                EditorView(project: project)
            }
            .alert("Something Went Wrong", isPresented: errorBinding) {
                Button("OK") { appModel.presentedError = nil }
            } message: {
                Text(appModel.presentedError ?? "")
            }
        }
        .task { await appModel.load() }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { appModel.presentedError != nil },
            set: { if !$0 { appModel.presentedError = nil } }
        )
    }
}

private struct ProjectCard: View {
    @Environment(AppModel.self) private var appModel
    @State private var isRenaming = false
    @State private var proposedName = ""
    let project: ArtProject

    var body: some View {
        Button {
            appModel.selectedProject = project
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    CheckerboardView(squareSize: 10)
                    Image(systemName: "scribble.variable")
                        .font(.system(size: 42))
                        .foregroundStyle(.secondary)
                }
                .frame(height: 120)
                .clipShape(.rect(cornerRadius: 14))

                Text(project.name)
                    .font(.headline)
                    .lineLimit(1)
                Text("\(project.canvas.width) × \(project.canvas.height)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .background(.regularMaterial, in: .rect(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Rename", systemImage: "pencil") {
                proposedName = project.name
                isRenaming = true
            }
            Button("Duplicate", systemImage: "plus.square.on.square") {
                Task { await appModel.duplicate(project) }
            }
            Button("Delete", systemImage: "trash", role: .destructive) {
                Task { await appModel.delete(project) }
            }
        }
        .alert("Rename Project", isPresented: $isRenaming) {
            TextField("Name", text: $proposedName)
            Button("Cancel", role: .cancel) {}
            Button("Rename") {
                var renamed = project
                renamed.name = proposedName.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                renamed.modifiedAt = Date()
                Task { await appModel.save(renamed) }
            }
            .disabled(
                proposedName.trimmingCharacters(in: .whitespacesAndNewlines)
                    .isEmpty
            )
        }
        .accessibilityLabel(
            "\(project.name), \(project.canvas.width) by \(project.canvas.height) pixels"
        )
    }
}
