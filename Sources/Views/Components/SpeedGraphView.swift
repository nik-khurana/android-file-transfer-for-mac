import SwiftUI

public struct SpeedGraphView: View {
    public var samples: [SpeedSample]
    public var maxSpeed: Double
    public var direction: TransferDirection
    
    public init(samples: [SpeedSample], maxSpeed: Double = 100.0, direction: TransferDirection = .writeToPhone) {
        self.samples = samples
        self.maxSpeed = maxSpeed
        self.direction = direction
    }
    
    private var chartColor: Color {
        direction == .readFromPhone ? Color.cyan : Color(red: 0.1, green: 0.85, blue: 0.5)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("REAL-TIME THROUGHPUT HISTORY")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "Max: %.1f MB/s", max(maxSpeed, 10.0)))
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let effectiveMax = max(10.0, maxSpeed * 1.1)
                
                ZStack {
                    // Grid lines
                    VStack {
                        Divider().background(Color.white.opacity(0.06))
                        Spacer()
                        Divider().background(Color.white.opacity(0.06))
                        Spacer()
                        Divider().background(Color.white.opacity(0.06))
                    }
                    
                    if samples.count > 1 {
                        // Area fill
                        Path { path in
                            let stepX = w / CGFloat(samples.count - 1)
                            path.move(to: CGPoint(x: 0, y: h))
                            
                            for (index, sample) in samples.enumerated() {
                                let norm = CGFloat(sample.speedMBs / effectiveMax)
                                let clampedNorm = min(1.0, max(0.0, norm))
                                let x = CGFloat(index) * stepX
                                let y = h - (clampedNorm * h)
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                            path.addLine(to: CGPoint(x: w, y: h))
                            path.closeSubpath()
                        }
                        .fill(
                            LinearGradient(
                                colors: [chartColor.opacity(0.25), chartColor.opacity(0.01)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        
                        // Line stroke
                        Path { path in
                            let stepX = w / CGFloat(samples.count - 1)
                            for (index, sample) in samples.enumerated() {
                                let norm = CGFloat(sample.speedMBs / effectiveMax)
                                let clampedNorm = min(1.0, max(0.0, norm))
                                let x = CGFloat(index) * stepX
                                let y = h - (clampedNorm * h)
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(chartColor, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                    }
                }
            }
            .frame(height: 75)
            .background(Color.black.opacity(0.2))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
    }
}

