//
//  BLEManager.swift
//  101
//
//  Created by 刘明 on 17/03/2026.
//

import CoreBluetooth
import Foundation

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var receivedText: String = ""
    var centralManager: CBCentralManager!
    
    // --- 核心改动：支持多设备 ---
    // 原有的 peripheral 留给 HM-10 使用，确保原有逻辑不报错
    var peripheral: CBPeripheral?
    // 新增：专门给打印机用的变量
    var printerPeripheral: CBPeripheral?
    
    // 原有的 txCharacteristic 留给 HM-10
    var txCharacteristic: CBCharacteristic?
    // 新增：打印机的写入特征值
    var printerCharacteristic: CBCharacteristic?

    var onReceive: ((String) -> Void)?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("蓝牙已开启，开始扫描")
            // 修改点：允许持续扫描，直到两个都连上，或者保持扫描以备设备掉线重连
            centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        }
    }

    // MARK: - 扫描逻辑 (兼容旧逻辑 + 新增打印机)
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber) {

        guard let name = peripheral.name else { return }

        // 1. 原有 HM-10 逻辑 (完全保留)
        if name.contains("HMSoft") {
            if self.peripheral == nil { // 防止重复连接
                self.peripheral = peripheral
                // 注意：不再调用 stopScan()，否则搜不到打印机
                centralManager.connect(peripheral)
                print("找到 HM-10，发起连接")
            }
        }
        
        // 2. 新增打印机扫描逻辑 (假设打印机名包含 "Printer")
        else if name.contains("Printer_C") {
            if self.printerPeripheral == nil {
                self.printerPeripheral = peripheral
                centralManager.connect(peripheral)
                print("找到打印机，发起连接")
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("连接成功: \(peripheral.name ?? "")")
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }

    // MARK: - 发现特征值 (根据设备分配 txCharacteristic)
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        let devName = peripheral.name ?? ""

        for char in characteristics {
            // 如果是 HM-10 的特征 (原有逻辑)
            if devName.contains("HMSoft") {
                if char.properties.contains(.notify) || char.properties.contains(.read) {
                    self.txCharacteristic = char
                    peripheral.setNotifyValue(true, for: char)
                    print("HM-10 特征订阅成功")
                }
            }
            // 如果是 打印机 的特征 (新增逻辑)
            else if devName.contains("Printer_C") {
                if char.properties.contains(.write) || char.properties.contains(.writeWithoutResponse) {
                    self.printerCharacteristic = char
                    print("打印机写入特征就绪")
                }
            }
        }
    }

    // MARK: - 原有收信号逻辑 (完全保留)
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // 只有当特征值属于 HM-10 时才触发原有逻辑
        if let data = characteristic.value, let text = String(data: data, encoding: .utf8) {
            let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedText.isEmpty {
                print("收到蓝牙信号: \(trimmedText)")
                DispatchQueue.main.async {
                    self.receivedText = trimmedText
                    self.onReceive?(trimmedText)
                }
            }
        }
    }
    
    // MARK: - 新增打印方法
    // MARK: - 通用的发送数据方法
    // 我们把名字改得更直接，它只负责把“指令包”扔给打印机
    func sendDataToPrinter(_ data: Data) {
        guard let p = printerPeripheral, let char = printerCharacteristic else {
            print("❌ 打印机未就绪")
            return
        }
        
        // 直接发送传进来的数据包
        p.writeValue(data, for: char, type: .withoutResponse)
        print("✅ 指令包已送往打印机")
    }
}
