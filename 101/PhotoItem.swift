//
//  PhotoItem.swift
//  101
//
//  Created by 刘明 on 27/02/2026.
//

import Foundation

struct PhotoItem: Identifiable, Codable {
    let id: UUID
    let imageFileName: String
    var note: String
    let createdAt: Date
}
