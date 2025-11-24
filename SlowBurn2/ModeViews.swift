import SwiftUI
import AppKit

// MARK: - Pixel Freeze Mode
struct PixelFreezeView: View {
    @Binding var intensity: Double
    @State private var frozenPixels: [(id: UUID, position: CGPoint, color: Color)] = []
    @State private var lastUpdate = Date()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(frozenPixels, id: \.id) { pixel in
                    Rectangle()
                        .fill(pixel.color)
                        .frame(width: 4, height: 4)
                        .position(pixel.position)
                }
            }
            .onChange(of: intensity) { oldValue, newValue in
                updateFrozenPixels(size: geometry.size)
            }
            .onAppear {
                updateFrozenPixels(size: geometry.size)
            }
        }
        .ignoresSafeArea()
    }
    
    private func updateFrozenPixels(size: CGSize) {
        let now = Date()
        guard now.timeIntervalSince(lastUpdate) > 0.05 else { return }
        lastUpdate = now
        
        // Calculate how many pixels should be frozen based on intensity
        let maxPixels = Int(intensity * size.width * size.height / 300) // More visible scaling
        let currentCount = frozenPixels.count
        
        if maxPixels > currentCount {
            // Add more frozen pixels with random colors (simulating frozen screen pixels)
            let toAdd = min(maxPixels - currentCount, 100) // Allow more additions per frame
            for _ in 0..<toAdd {
                let x = CGFloat.random(in: 0..<size.width)
                let y = CGFloat.random(in: 0..<size.height)
                // Random color to simulate frozen pixel
                let color = Color(
                    red: Double.random(in: 0...1),
                    green: Double.random(in: 0...1),
                    blue: Double.random(in: 0...1)
                )
                frozenPixels.append((id: UUID(), position: CGPoint(x: x, y: y), color: color))
            }
        } else if maxPixels < currentCount {
            // Remove pixels when intensity decreases
            let toRemove = currentCount - maxPixels
            frozenPixels.removeFirst(min(toRemove, 100))
        }
        
        // Ensure we have at least some pixels even at low intensity for visibility
        if intensity > 0.01 && frozenPixels.isEmpty {
            let minPixels = max(1, Int(intensity * 100))
            for _ in 0..<minPixels {
                let x = CGFloat.random(in: 0..<size.width)
                let y = CGFloat.random(in: 0..<size.height)
                let color = Color(
                    red: Double.random(in: 0...1),
                    green: Double.random(in: 0...1),
                    blue: Double.random(in: 0...1)
                )
                frozenPixels.append((id: UUID(), position: CGPoint(x: x, y: y), color: color))
            }
        }
    }
}

// MARK: - Pixel Blackout Mode
struct PixelBlackoutView: View {
    @Binding var intensity: Double
    @State private var blackedPixels: [(id: UUID, position: CGPoint)] = []
    @State private var currentSize: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // DEBUG: Red overlay to verify window is visible (reduced opacity)
                Rectangle()
                    .fill(Color.red.opacity(intensity * 0.1))
                
                // DEBUG: Large text to verify window is there
                VStack {
                    Text("PIXEL BLACKOUT ACTIVE")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundColor(.white)
                    Text("Intensity: \(Int(intensity * 100))%")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.yellow)
                    Text("Pixels: \(blackedPixels.count)")
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                }
                
                // Black pixels - make them bigger and more visible
                ForEach(blackedPixels, id: \.id) { pixel in
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: 10, height: 10)
                        .position(pixel.position)
                }
            }
            .onChange(of: intensity) { oldValue, newValue in
                currentSize = geometry.size
                updateBlackedPixels()
            }
            .onChange(of: geometry.size) { oldValue, newValue in
                currentSize = newValue
                updateBlackedPixels()
            }
            .onAppear {
                currentSize = geometry.size
                updateBlackedPixels()
            }
        }
        .ignoresSafeArea()
    }
    
    private func updateBlackedPixels() {
        guard currentSize.width > 0 && currentSize.height > 0 else { return }
        guard intensity > 0 else {
            blackedPixels = []
            return
        }
        
        // Calculate target number of pixels based on intensity
        // At 100% intensity, we want about 30% of screen covered with 10x10 pixel blocks
        // For a 1920x1080 screen: ~62,000 pixels total, 30% = ~18,600 pixels
        // With 10x10 blocks, that's ~186 blocks
        // So we scale: intensity * screen_area / (10 * 10 * 3.33) to get ~30% coverage at max
        let pixelSize: CGFloat = 10
        let targetCoverage = intensity * 0.3 // 30% coverage at max intensity
        let totalPixels = (currentSize.width / pixelSize) * (currentSize.height / pixelSize)
        let maxPixels = Int(totalPixels * targetCoverage)
        
        let currentCount = blackedPixels.count
        
        if maxPixels > currentCount {
            // Add pixels
            let toAdd = min(maxPixels - currentCount, 500) // Allow more additions per update
            for _ in 0..<toAdd {
                let x = CGFloat.random(in: 0..<currentSize.width)
                let y = CGFloat.random(in: 0..<currentSize.height)
                blackedPixels.append((id: UUID(), position: CGPoint(x: x, y: y)))
            }
        } else if maxPixels < currentCount {
            // Remove pixels when intensity decreases
            let toRemove = currentCount - maxPixels
            blackedPixels.removeFirst(min(toRemove, 500))
        }
    }
}

// MARK: - Sleepy Emoji Mode
struct SleepyEmojiView: View {
    @Binding var intensity: Double
    @State private var emojis: [(id: UUID, position: CGPoint, emoji: String)] = []
    
    private let sleepyEmojis = ["😴", "💤", "😪", "🥱", "😵", "🛌"]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(emojis, id: \.id) { emojiData in
                    Text(emojiData.emoji)
                        .font(.system(size: 30 + intensity * 20))
                        .position(emojiData.position)
                }
            }
            .onChange(of: intensity) { oldValue, newValue in
                updateEmojis(size: geometry.size)
            }
            .onAppear {
                updateEmojis(size: geometry.size)
            }
        }
        .ignoresSafeArea()
    }
    
    private func updateEmojis(size: CGSize) {
        let targetCount = Int(intensity * 200) // Max 200 emojis
        let currentCount = emojis.count
        
        if targetCount > currentCount {
            let toAdd = targetCount - currentCount
            for _ in 0..<toAdd {
                let x = CGFloat.random(in: 0..<size.width)
                let y = CGFloat.random(in: 0..<size.height)
                let emoji = sleepyEmojis.randomElement() ?? "😴"
                emojis.append((id: UUID(), position: CGPoint(x: x, y: y), emoji: emoji))
            }
        }
    }
}

// MARK: - Distortion Mode
struct DistortionView: View {
    @Binding var intensity: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Multiple distortion layers
                ForEach(0..<Int(intensity * 10), id: \.self) { index in
                    DistortionLayer(intensity: intensity, index: index)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
    }
}

struct DistortionLayer: View {
    let intensity: Double
    let index: Int
    
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                // Create wavy distortion effect
                let waveCount = 5.0 + intensity * 10.0
                let amplitude = intensity * 50.0
                
                var path = Path()
                for y in stride(from: 0, through: size.height, by: 10) {
                    let wave = sin((Double(y) / size.height) * waveCount * .pi * 2.0 + Double(index) * 0.5) * amplitude
                    let x = size.width / 2.0 + wave
                    
                    if y == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                
                context.stroke(path, with: .color(.white.opacity(0.3)), lineWidth: 2)
            }
        }
        .blur(radius: intensity * 30)
        .opacity(intensity * 0.6)
    }
}

// MARK: - Messages Mode
struct MessagesView: View {
    @Binding var intensity: Double
    @State private var messages: [(id: UUID, text: String, position: CGPoint)] = []
    
    private let messageTexts = [
        "Hey - go to bed",
        "For real, it's time to sleep",
        "You're tired",
        "Stop staring at the screen",
        "Go to sleep already",
        "Your eyes need rest",
        "It's way past bedtime",
        "Time to wind down",
        "Close your laptop",
        "Sleep is calling",
        "You know you're tired",
        "Just go to bed",
        "Seriously, go sleep"
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(messages, id: \.id) { message in
                    Text(message.text)
                        .font(.system(size: 24 + intensity * 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                        .position(message.position)
                }
            }
            .onChange(of: intensity) { oldValue, newValue in
                updateMessages(size: geometry.size)
            }
            .onAppear {
                updateMessages(size: geometry.size)
            }
        }
        .ignoresSafeArea()
    }
    
    private func updateMessages(size: CGSize) {
        let targetCount = Int(intensity * 15) // Max 15 messages
        let currentCount = messages.count
        
        if targetCount > currentCount {
            let toAdd = targetCount - currentCount
            for _ in 0..<toAdd {
                let x = CGFloat.random(in: 100..<(size.width - 100))
                let y = CGFloat.random(in: 100..<(size.height - 100))
                let text = messageTexts.randomElement() ?? "Go to bed"
                messages.append((id: UUID(), text: text, position: CGPoint(x: x, y: y)))
            }
        }
    }
}

// MARK: - Side Swipe Mode
struct SideSwipeView: View {
    @Binding var intensity: Double
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Rainbow gradient swipe
                LinearGradient(
                    colors: [
                        .red, .orange, .yellow, .green, .blue, .indigo, .purple
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: geometry.size.width * intensity)
                .opacity(0.7 + intensity * 0.3)
                
                Spacer()
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
    }
}

