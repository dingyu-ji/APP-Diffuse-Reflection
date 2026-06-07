//
//  ImageMatcher.swift
//  101
//
//  Created by 刘明 on 08/03/2026.
//

import Foundation

struct ImageMatcher {

    static func match(selectedWords: [String], gallery: [GalleryImage]) -> String? {

        guard !selectedWords.isEmpty else { return nil }

        var bestImage: GalleryImage?
        var maxMatch = 0

        for image in gallery {
            let matchCount = image.keywords.filter { selectedWords.contains($0) }.count
            if matchCount > maxMatch {
                maxMatch = matchCount
                bestImage = image
            }
        }

        return bestImage?.name
    }
}

//struct GalleryImage {
//    let name: String
//    let keywords: [String]
//}

