import SwiftUI

public struct SpeedometerView: View {
    public var speedMBs: Double
    public var peakMBs: Double
    public var maxScale: Double = 150.0
    public var direction: TransferDirection = .writeToPhone
    public var isTransferring: Bool = false
    
    public init(speedMBs: Double, peakMBs: Double, maxScale: Double = 150.0, direction: TransferDirection = .writeToPhone, isTransferring: Bool = false) {
        self.speedMBs = speedMBs
        self.peakMBs = peakMBs
        self.maxScale = maxScale
        self.direction = direction
        self.isTransferring = isTransferring
    }
    
    private var normalizedProgress: Double {
        let effectiveMax = max(maxScale, peakMBs * 1.15)
        return min(1.0, max(0.0, speedMBs / effectiveMax))
    }
    
    private var gradientColors: [Color] {
        if direction == .readFromPhone {
            return [Color.blue.opacity(0.4), Color.cyan, Color(red: 0.2, green: 0.6, blue: 1.0)]
        } else {
            return [Color.teal.opacity(0.4), Color.green, Color(red: 0.1, green: 0.9, blue: 0.6)]
        }
    }
    
    public var body: some View {
        ZStack {
            // Background arc track
            Circle()
                .trim(from: 0.15, to: 0.85)
                .stroke(Color.white.opacity(0.08), style: StrokeStyle(lineWidth: 18, lineCap: .round))
                .rotationEffect(.degrees(90))
                .frame(width: 200, height: 200)
            
            // Active colored progress arc
            Circle()
                .trim(from: 0.15, to: 0.15 + (0.70 * normalizedProgress))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: gradientColors),
                        center: .center,
                        startAngle: .degrees(140),
                        endAngle: .degrees(400)
                    ),
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )
                .rotationEffect(.degrees(90))
                .frame(width: 200, height: 200)
                .animation(.easeOut(duration: 0.2), value: normalizedProgress)
            
            // Center Readout
            VStack(spacing: 2) {
                // Direction Badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(isTransferring ? (direction == .readFromPhone ? Color.cyan : Color.green) : Color.gray)
                        .frame(width: 8, height: 8)
                        .shadow(color: isTransferring ? (direction == .readFromPhone ? Color.cyan : Color.green) : Color.clear, radius: 4)
                    
                    Text(direction == .readFromPhone ? "READ SPEED" : "WRITE SPEED")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                Text(String(format: "%.1f", speedMBs))
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("MB/s")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                
                // Peak speed pill
                if peakMBs > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.orange)
                        Text(String(format: "Peak: %.1f MB/s", peakMBs))
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
                    .padding(.top, 4)
                }
            }
        }
    }
}

