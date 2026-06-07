//
//  Typography.swift
//  101
//
//  Created by 刘明 on 20/03/2026.
//

import SwiftUI

struct AppFont {

    // 默认统一的行间距和字间距
    static let defaultLineSpacing: CGFloat = 10
    static let defaultKerning: CGFloat = 0.5

    // -----------------------------
    // 正文 Story 段落
    // -----------------------------
    static func story(size: CGFloat = 17) -> some ViewModifier {
        FontModifier(
            font: .custom("ziyueyinyingsong-s-Regular", size: size),
            lineSpacing: defaultLineSpacing,
            kerning: defaultKerning
        )
    }

    // -----------------------------
    // Section 标题
    // -----------------------------
    static func title(size: CGFloat = 22) -> some ViewModifier {
        FontModifier(
            font: .custom("ziyueyinyingsong-s-Regular", size: size),
            lineSpacing: defaultLineSpacing,
            kerning: defaultKerning
        )
    }

    // -----------------------------
    // 按钮文字 / 小段文字
    // -----------------------------
    static func button(size: CGFloat = 16) -> some ViewModifier {
        FontModifier(
            font: .custom("ziyueyinyingsong-s-Regular", size: size),
            lineSpacing: defaultLineSpacing,
            kerning: defaultKerning
        )
    }

    // -----------------------------
    // Caption / 辅助文字
    // -----------------------------
    static func caption(size: CGFloat = 13) -> some ViewModifier {
        FontModifier(
            font: .custom("ziyueyinyingsong-s-Regular", size: size),
            lineSpacing: defaultLineSpacing,
            kerning: defaultKerning
        )
    }
}

// -----------------------------
// 通用字体修饰器
// -----------------------------
struct FontModifier: ViewModifier {
    let font: Font
    let lineSpacing: CGFloat
    let kerning: CGFloat

    func body(content: Content) -> some View {
        content
            .font(font)
            .lineSpacing(lineSpacing)
            .kerning(kerning)
    }
}

extension View {
    func appFont(_ modifier: some ViewModifier) -> some View {
        self.modifier(modifier)
    }
}
