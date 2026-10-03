//
//  TemplateRepository.swift
//  Inklume
//
//  Created by Tufan Cakir on 03.10.26.
//

import Foundation

actor TemplateRepository {
    enum RepositoryError: LocalizedError {
        case missingCatalog

        var errorDescription: String? {
            "The bundled template catalog could not be loaded."
        }
    }

    func loadCatalog() throws -> TemplateCatalog {
        guard
            let url = Bundle.main.url(
                forResource: "Templates",
                withExtension: "json"
            )
        else {
            throw RepositoryError.missingCatalog
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(TemplateCatalog.self, from: data)
    }
}
