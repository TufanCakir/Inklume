//
//  AppModel.swift
//  Inklume
//
//  Created by Tufan Cakir on 03.10.26.
//

import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class AppModel {
    var projects: [ArtProject] = []
    var templates: [TemplateDefinition] = []
    var selectedProject: ArtProject?
    var presentedError: String?
    var isCreatingProject = false

    private let projectRepository = ProjectRepository()
    private let templateRepository = TemplateRepository()

    func load() async {
        do {
            async let loadedProjects = projectRepository.loadProjects()
            async let catalog = templateRepository.loadCatalog()
            projects = try await loadedProjects
            templates = try await catalog.templates
        } catch {
            presentedError = error.localizedDescription
        }
    }

    func createProject(
        name: String,
        template: TemplateDefinition?,
        configuration: CanvasConfiguration
    ) async {
        var project = ArtProject.blank(
            name: name,
            canvas: configuration,
            templateID: template?.id
        )
        project.modifiedAt = Date()
        do {
            try await projectRepository.save(project)
            projects.insert(project, at: 0)
            selectedProject = project
            isCreatingProject = false
        } catch {
            presentedError = error.localizedDescription
        }
    }

    func save(_ project: ArtProject) async {
        do {
            try await projectRepository.save(project)
            if let index = projects.firstIndex(where: { $0.id == project.id }) {
                projects[index] = project
            }
        } catch {
            presentedError = error.localizedDescription
        }
    }

    func duplicate(_ project: ArtProject) async {
        var copy = project
        copy.id = UUID()
        copy.name += " Copy"
        copy.createdAt = Date()
        copy.modifiedAt = Date()
        await save(copy)
        projects.insert(copy, at: 0)
    }

    func delete(_ project: ArtProject) async {
        do {
            try await projectRepository.delete(project)
            projects.removeAll { $0.id == project.id }
        } catch {
            presentedError = error.localizedDescription
        }
    }
}
