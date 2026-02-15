//
//  DueSoonView.swift
//  QueueDeadline
//
//  SectionHeader reusable component (DueSoonView replaced by QueueView)

import SwiftUI

struct SectionHeader: View {
    let title: String
    let color: Color
    let count: Int

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            Text("\(count)")
                .font(.caption2)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(color)
                .cornerRadius(8)

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}
