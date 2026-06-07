//
//  StoryParaView.swift
//  101
//
//  Created by 刘明 on 08/03/2026.
//

import SwiftUI

struct StoryParaView: View {

    var paragraph: StoryParagraph
    var onTap: () -> Void

    var body: some View {

        VStack(alignment: .leading, spacing: 12) {

            Text(paragraph.text)
                .appFont(AppFont.story())

            Button(action: onTap) {

                ZStack {

                    RoundedRectangle(cornerRadius: 10)
                        .stroke(style: StrokeStyle(
                            lineWidth: 2,
                            dash: [6]
                        ))

                    if let image = paragraph.matchedImage {

                        Image(image)
                            .resizable()
                            .scaledToFit()
                            .padding()

                    } else {

                        Text("")
                            .foregroundColor(.gray)
                    }
                }
                .frame(height: 140)
            }
        }
    }
}
