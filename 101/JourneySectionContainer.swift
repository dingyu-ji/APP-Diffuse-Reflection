//
//  JourneySectionContainer.swift
//  101
//
//  Created by 刘明 on 10/03/2026.
//

import SwiftUI

struct JourneySectionContainer<Content: View>: View {
    let title: String
    let content: Content

    // 构造函数
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .appFont(AppFont.title())
                .bold()

            content
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(hex: "FFF9D6")) // 低饱和度淡黄色
        .cornerRadius(12)
    }
}
