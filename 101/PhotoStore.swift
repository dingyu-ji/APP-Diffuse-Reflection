//
//  PhotoStore.swift
//  101
//
//  Created by 刘明 on 27/02/2026.
//

import Foundation
import UIKit

class PhotoStore: ObservableObject {

    @Published var photos: [PhotoItem] = []

    private let saveKey = "saved_photos"

    init() {
        load()
    }

    // MARK: - Add Photo
    func addPhoto(_ image: UIImage) {
        let id = UUID()
        let fileName = "\(id).jpg"

        if let data = image.jpegData(compressionQuality: 0.9) {
            let url = getDocumentsDirectory().appendingPathComponent(fileName)
            try? data.write(to: url)

            let newItem = PhotoItem(
                id: id,
                imageFileName: fileName,
                note: "",
                createdAt: Date()
            )

            photos.insert(newItem, at: 0) // 最新在前（类似苹果相册）
            save()
        }
    }

    // MARK: - Delete
    func delete(_ item: PhotoItem) {
        let url = getDocumentsDirectory().appendingPathComponent(item.imageFileName)
        try? FileManager.default.removeItem(at: url)
        photos.removeAll { $0.id == item.id }
        save()
    }

    // MARK: - Update Note
    func updateNote(for item: PhotoItem, note: String) {
        if let index = photos.firstIndex(where: { $0.id == item.id }) {
            photos[index].note = note
            save()
        }
    }

    // MARK: - Load Image
    func loadImage(for item: PhotoItem) -> UIImage? {
        let url = getDocumentsDirectory().appendingPathComponent(item.imageFileName)
        return UIImage(contentsOfFile: url.path)
    }

    // MARK: - Persistence
    private func save() {
        if let data = try? JSONEncoder().encode(photos) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([PhotoItem].self, from: data) {
            photos = decoded
        }
    }

    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
