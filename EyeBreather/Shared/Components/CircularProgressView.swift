// EyeBreather/Shared/Components/CircularProgressView.swift
import SwiftUI

/// 圆环进度视图
struct CircularProgressView: View {
    let progress: Double  // 0.0 - 1.0
    let timeText: String
    let subtitle: String
    let color: Color
    let size: CGFloat
    
    init(
        progress: Double,
        timeText: String,
        subtitle: String = "",
        color: Color = .accentColor,
        size: CGFloat = 120
    ) {
        self.progress = progress
        self.timeText = timeText
        self.subtitle = subtitle
        self.color = color
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // 背景圆环
            Circle()
                .stroke(
                    color.opacity(0.2),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
            
            // 进度圆环
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
            
            // 中心文字
            VStack(spacing: 2) {
                Text(timeText)
                    .font(.system(size: size * 0.25, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: size * 0.1))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    VStack(spacing: 20) {
        CircularProgressView(
            progress: 0.7,
            timeText: "18:32",
            subtitle: "下次休息",
            color: .green
        )
        
        CircularProgressView(
            progress: 0.3,
            timeText: "0:15",
            subtitle: "休息中",
            color: .blue,
            size: 100
        )
    }
    .padding()
}
