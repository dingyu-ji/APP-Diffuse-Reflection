//
//  Color+Hex.swift
//  101
//
//  Created by 刘明 on 06/03/2026.
//

import SwiftUI

extension Color {

    init(hex: String) {

        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0

        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b: UInt64

        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 255, (int >> 8) & 255, int & 255)
        default:
            (r, g, b) = (0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
    
    // ✅ 新增：获取 RGB 分量
    var red: Double { Double(UIColor(self).cgColor.components?[0] ?? 0) }
    var green: Double { Double(UIColor(self).cgColor.components?[1] ?? 0) }
    var blue: Double { Double(UIColor(self).cgColor.components?[2] ?? 0) }

}
