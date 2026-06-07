//
//  PhotoCaptureDelegate.swift
//  101
//
//  Created by 刘明 on 27/02/2026.
//

import AVFoundation
import UIKit

class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {

    let photoStore: PhotoStore
    let journeyRecorder: JourneyRecorder   // ✅ 加这个

    init(photoStore: PhotoStore,
         journeyRecorder: JourneyRecorder) {
        self.photoStore = photoStore
        self.journeyRecorder = journeyRecorder
    }

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {

        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }

        DispatchQueue.main.async {

            // 1️⃣ 存入相册
            self.photoStore.addPhoto(image)

            // 2️⃣ 记录到 JourneyRecorder（文字 + 照片）
            self.journeyRecorder.recordPhoto(image)
        }
    }
}
