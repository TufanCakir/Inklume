//
//  InklumeTests.swift
//  Inklume
//
//  Created by Tufan Cakir on 03.10.26.
//

import Foundation
import Testing

@testable import Inklume

struct InklumeTests {
    @Test func templateCatalogDecodes() throws {
        let json = """
            {"version":1,"templates":[{"id":"sprite","name":"Sprite","category":"Game","symbolName":"figure.walk","width":64,"height":64,"transparentByDefault":true,"tags":["game"]}]}
            """
        let catalog = try JSONDecoder().decode(
            TemplateCatalog.self,
            from: Data(json.utf8)
        )
        #expect(catalog.templates.count == 1)
        #expect(catalog.templates[0].transparentByDefault)
    }

    @Test func projectRoundTripPreservesEditableState() throws {
        var project = ArtProject.blank()
        project.layers.append(
            ArtLayer(name: "Reference", opacity: 0.5, kind: .referenceImage)
        )
        project.timeline.keyframes.append(
            LayerKeyframe(
                time: 0.5,
                layerID: project.layers[0].id,
                transform: LayerTransform(x: 10),
                opacity: 0.75,
                isVisible: true,
                interpolation: .easeInOut
            )
        )

        let data = try JSONEncoder().encode(project)
        let decoded = try JSONDecoder().decode(ArtProject.self, from: data)

        #expect(decoded == project)
        #expect(decoded.layers.count == 2)
        #expect(decoded.timeline.keyframes.count == 1)
    }

    @Test func legacyProjectWithoutDepthDataStillDecodes() throws {
        let project = ArtProject.blank()
        let encoded = try JSONEncoder().encode(project)
        var json = try #require(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )
        json.removeValue(forKey: "camera")

        if var layers = json["layers"] as? [[String: Any]] {
            for index in layers.indices {
                layers[index].removeValue(forKey: "depthSettings")
            }
            json["layers"] = layers
        }

        let legacyData = try JSONSerialization.data(withJSONObject: json)
        let decoded = try JSONDecoder().decode(
            ArtProject.self,
            from: legacyData
        )

        #expect(decoded.camera == nil)
        #expect(decoded.layers.first?.depthSettings == nil)
    }

    @Test func interpolationModesAreDeterministic() {
        #expect(
            AnimationEngine.progress(at: 0.5, from: 0, to: 1, mode: .linear)
                == 0.5
        )
        #expect(
            AnimationEngine.progress(at: 0.5, from: 0, to: 1, mode: .hold) == 0
        )
        #expect(
            AnimationEngine.progress(at: 1, from: 0, to: 1, mode: .hold) == 1
        )
        #expect(AnimationEngine.interpolate(10, 20, progress: 0.25) == 12.5)
    }

    @Test func spriteSheetDimensionsIncludeSpacingAndPadding() {
        let configuration = FrameConfiguration(
            frameWidth: 64,
            frameHeight: 32,
            columns: 4,
            rows: 2,
            horizontalSpacing: 2,
            verticalSpacing: 3,
            padding: 5
        )
        let layout = SpriteSheetLayout(configuration: configuration)

        #expect(layout.pixelWidth == 272)
        #expect(layout.pixelHeight == 77)
    }
}
