//
//  modelCache.swift
//  101
//
//  Created by 刘明 on 26/03/2026.
//

import RealityKit

class ModelCache {
    static let shared = ModelCache()
    private var models: [String: ModelEntity] = [:]

    func loadModel(named name: String) throws -> ModelEntity {
        if let cached = models[name] {
            return cached.clone(recursive: true)
        }
        let model = try ModelEntity.loadModel(named: name)
        models[name] = model
        return model.clone(recursive: true)
    }
}
