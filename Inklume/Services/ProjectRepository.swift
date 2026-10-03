//
//  ProjectRepository.swift
//  Inklume
//
//  Created by Tufan Cakir on 03.10.26.
//

import Foundation

actor ProjectRepository {
    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init() {
        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    func loadProjects() throws -> [ArtProject] {
        let directory = try projectsDirectory()
        let urls = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )
        return
            urls
            .filter { $0.pathExtension == "inkproject" }
            .compactMap {
                try? Data(contentsOf: $0.appending(path: "project.json"))
            }
            .compactMap { try? decoder.decode(ArtProject.self, from: $0) }
            .sorted { $0.modifiedAt > $1.modifiedAt }
    }

    func save(_ project: ArtProject) throws {
        let package = try packageURL(for: project.id)
        try fileManager.createDirectory(
            at: package,
            withIntermediateDirectories: true
        )
        try fileManager.createDirectory(
            at: package.appending(path: "layers"),
            withIntermediateDirectories: true
        )
        try fileManager.createDirectory(
            at: package.appending(path: "assets"),
            withIntermediateDirectories: true
        )
        try fileManager.createDirectory(
            at: package.appending(path: "previews"),
            withIntermediateDirectories: true
        )
        try fileManager.createDirectory(
            at: package.appending(path: "animation"),
            withIntermediateDirectories: true
        )
        let data = try encoder.encode(project)
        try data.write(
            to: package.appending(path: "project.json"),
            options: .atomic
        )
    }

    func delete(_ project: ArtProject) throws {
        let url = try packageURL(for: project.id)
        guard fileManager.fileExists(atPath: url.path) else { return }
        try fileManager.removeItem(at: url)
    }

    private func projectsDirectory() throws -> URL {
        let base = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = base.appending(
            path: "Projects",
            directoryHint: .isDirectory
        )
        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        return directory
    }

    private func packageURL(for id: UUID) throws -> URL {
        try projectsDirectory().appending(path: id.uuidString)
            .appendingPathExtension("inkproject")
    }
}
