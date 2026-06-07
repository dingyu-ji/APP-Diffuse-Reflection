//
//  NFCManager.swift
//  101
//
//  Created by 刘明 on 05/03/2026.
//

import CoreNFC

class NFCManager: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {

    var session: NFCNDEFReaderSession?
    var onTagDetected: ((String) -> Void)?

    func startScanning() {

        guard NFCNDEFReaderSession.readingAvailable else {
            print("NFC 不可用")
            return
        }

        session = NFCNDEFReaderSession(delegate: self,
                                       queue: nil,
                                       invalidateAfterFirstRead: true)

        session?.alertMessage = "请将手机靠近景点贴纸"
        session?.begin()
    }

    // 读取成功
    func readerSession(_ session: NFCNDEFReaderSession,
                       didDetectNDEFs messages: [NFCNDEFMessage]) {

        guard let record = messages.first?.records.first else { return }

        if let text = String(data: record.payload.advanced(by: 3), encoding: .utf8) {

            DispatchQueue.main.async {
                self.onTagDetected?(text)
            }
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession,
                       didInvalidateWithError error: Error) {
        print("NFC session 结束")
    }
}
