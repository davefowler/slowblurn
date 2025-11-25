import SwiftUI
import AppKit
import CoreGraphics

// MARK: - Confetti Mode (formerly Pixel Freeze)
struct ConfettiView: View {
    @Binding var intensity: Double
    @State private var frozenPixels: [(id: UUID, position: CGPoint, color: Color)] = []
    @State private var currentSize: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(frozenPixels, id: \.id) { pixel in
                    Rectangle()
                        .fill(pixel.color)
                        .frame(width: 8, height: 8)
                        .position(pixel.position)
                }
            }
            .onChange(of: intensity) { oldValue, newValue in
                currentSize = geometry.size
                updateFrozenPixels()
            }
            .onChange(of: geometry.size) { oldValue, newValue in
                currentSize = newValue
                updateFrozenPixels()
            }
            .onAppear {
                currentSize = geometry.size
                updateFrozenPixels()
            }
        }
        .ignoresSafeArea()
    }
    
    private func updateFrozenPixels() {
        guard currentSize.width > 0 && currentSize.height > 0 else { return }
        guard intensity > 0 else {
            frozenPixels = []
            return
        }
        
        // Calculate target number of pixels based on intensity
        let pixelSize: CGFloat = 8
        let targetCoverage = intensity * 0.25 // 25% coverage at max intensity
        let totalPixels = (currentSize.width / pixelSize) * (currentSize.height / pixelSize)
        let maxPixels = Int(totalPixels * targetCoverage)
        
        let currentCount = frozenPixels.count
        
        if maxPixels > currentCount {
            // Add more frozen pixels with random colors (simulating frozen screen pixels)
            let toAdd = min(maxPixels - currentCount, 500)
            for _ in 0..<toAdd {
                let x = CGFloat.random(in: 0..<currentSize.width)
                let y = CGFloat.random(in: 0..<currentSize.height)
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
            frozenPixels.removeFirst(min(toRemove, 500))
        }
    }
}

// MARK: - Pixel Freeze Mode (tracks frozen pixels with 2D grid)
struct PixelFreezeView: View {
    @Binding var intensity: Double
    @State private var frozenPixels: [(id: UUID, position: CGPoint, color: Color)] = []
    @State private var frozenGrid: Set<String> = [] // 2D grid tracking frozen positions
    @State private var currentSize: CGSize = .zero
    @State private var lastIntensity: Double = 0.0
    
    private let pixelSize: CGFloat = 5
    
    // Generate a "frozen" color - mix of blues/whites to simulate frozen effect
    private func generateFrozenColor() -> Color {
        let random = Double.random(in: 0...1)
        if random < 0.3 {
            // Light blue/cyan
            return Color(
                red: 0.7 + Double.random(in: 0...0.3),
                green: 0.8 + Double.random(in: 0...0.2),
                blue: 0.9 + Double.random(in: 0...0.1)
            )
        } else if random < 0.6 {
            // White/light gray
            return Color(
                red: 0.8 + Double.random(in: 0...0.2),
                green: 0.8 + Double.random(in: 0...0.2),
                blue: 0.8 + Double.random(in: 0...0.2)
            )
        } else {
            // Slight blue tint
            return Color(
                red: 0.6 + Double.random(in: 0...0.4),
                green: 0.7 + Double.random(in: 0...0.3),
                blue: 0.85 + Double.random(in: 0...0.15)
            )
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Frozen pixels
                ForEach(frozenPixels, id: \.id) { pixel in
                    Rectangle()
                        .fill(pixel.color)
                        .frame(width: pixelSize, height: pixelSize)
                        .position(pixel.position)
                }
            }
            .onChange(of: intensity) { oldValue, newValue in
                currentSize = geometry.size
                updateFrozenPixels(oldIntensity: oldValue, newIntensity: newValue)
            }
            .onChange(of: geometry.size) { oldValue, newValue in
                if abs(newValue.width - currentSize.width) > 10 || abs(newValue.height - currentSize.height) > 10 {
                    currentSize = newValue
                    regeneratePixelsForNewSize()
                }
            }
            .onAppear {
                currentSize = geometry.size
                lastIntensity = intensity
                updateFrozenPixels(oldIntensity: 0.0, newIntensity: intensity)
            }
        }
        .ignoresSafeArea()
    }
    
    private func gridKey(for position: CGPoint) -> String {
        let gridX = Int(position.x / pixelSize)
        let gridY = Int(position.y / pixelSize)
        return "\(gridX),\(gridY)"
    }
    
    private func calculateMaxPixels() -> Int {
        guard currentSize.width > 0 && currentSize.height > 0 else { return 0 }
        let gridWidth = Int(currentSize.width / pixelSize)
        let gridHeight = Int(currentSize.height / pixelSize)
        return gridWidth * gridHeight
    }
    
    private func regeneratePixelsForNewSize() {
        let maxPixels = calculateMaxPixels()
        let targetCount = Int(intensity * Double(maxPixels))
        frozenPixels = []
        frozenGrid = []
        
        for _ in 0..<targetCount {
            if let position = findUnoccupiedPosition() {
                let color = generateFrozenColor()
                frozenPixels.append((id: UUID(), position: position, color: color))
                frozenGrid.insert(gridKey(for: position))
            }
        }
    }
    
    private func findUnoccupiedPosition() -> CGPoint? {
        guard currentSize.width > 0 && currentSize.height > 0 else { return nil }
        
        let gridWidth = Int(currentSize.width / pixelSize)
        let gridHeight = Int(currentSize.height / pixelSize)
        let totalPositions = gridWidth * gridHeight
        
        if frozenGrid.count >= totalPositions {
            return nil
        }
        
        var attempts = 0
        let maxAttempts = totalPositions * 2
        
        while attempts < maxAttempts {
            let gridX = Int.random(in: 0..<gridWidth)
            let gridY = Int.random(in: 0..<gridHeight)
            let key = "\(gridX),\(gridY)"
            
            if !frozenGrid.contains(key) {
                let x = CGFloat(gridX) * pixelSize + pixelSize / 2
                let y = CGFloat(gridY) * pixelSize + pixelSize / 2
                return CGPoint(x: x, y: y)
            }
            
            attempts += 1
        }
        
        return nil
    }
    
    private func updateFrozenPixels(oldIntensity: Double, newIntensity: Double) {
        guard currentSize.width > 0 && currentSize.height > 0 else { return }
        
        if newIntensity <= 0 {
            frozenPixels = []
            frozenGrid = []
            lastIntensity = 0.0
            return
        }
        
        // If intensity changed significantly (more than 20%), regenerate from scratch
        // This ensures manual control works properly
        let intensityDelta = abs(newIntensity - oldIntensity)
        if intensityDelta > 0.2 || oldIntensity == 0.0 {
            regeneratePixelsForIntensity(newIntensity)
            lastIntensity = newIntensity
            return
        }
        
        let maxPixels = calculateMaxPixels()
        let targetCount = Int(newIntensity * Double(maxPixels))
        let currentCount = frozenPixels.count
        
        if targetCount > currentCount {
            // Add pixels if intensity increased
            let toAdd = min(targetCount - currentCount, 500)
            for _ in 0..<toAdd {
                if let position = findUnoccupiedPosition() {
                    let color = generateFrozenColor()
                    frozenPixels.append((id: UUID(), position: position, color: color))
                    frozenGrid.insert(gridKey(for: position))
                } else {
                    break
                }
            }
        } else if targetCount < currentCount {
            // Remove pixels if intensity decreased
            let toRemove = currentCount - targetCount
            // Remove from the end (most recently added)
            frozenPixels.removeLast(min(toRemove, frozenPixels.count))
            // Rebuild grid from remaining pixels
            frozenGrid = Set(frozenPixels.map { gridKey(for: $0.position) })
        }
        
        lastIntensity = newIntensity
    }
    
    private func regeneratePixelsForIntensity(_ targetIntensity: Double) {
        let maxPixels = calculateMaxPixels()
        let targetCount = Int(targetIntensity * Double(maxPixels))
        frozenPixels = []
        frozenGrid = []
        
        for _ in 0..<targetCount {
            if let position = findUnoccupiedPosition() {
                let color = generateFrozenColor()
                frozenPixels.append((id: UUID(), position: position, color: color))
                frozenGrid.insert(gridKey(for: position))
            } else {
                break
            }
        }
    }
}

// MARK: - Pixel Blackout Mode
struct PixelBlackoutView: View {
    @Binding var intensity: Double
    @State private var blackedPixels: [(id: UUID, position: CGPoint)] = []
    @State private var occupiedPositions: Set<String> = [] // Track occupied grid positions
    @State private var currentSize: CGSize = .zero
    @State private var lastIntensity: Double = 0.0
    
    private let pixelSize: CGFloat = 5 // Smaller pixels
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Black pixels - smaller and non-overlapping
                ForEach(blackedPixels, id: \.id) { pixel in
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: pixelSize, height: pixelSize)
                        .position(pixel.position)
                }
            }
            .onChange(of: intensity) { oldValue, newValue in
                currentSize = geometry.size
                updateBlackedPixels(oldIntensity: oldValue, newIntensity: newValue)
            }
            .onChange(of: geometry.size) { oldValue, newValue in
                // Only update if size actually changed significantly
                if abs(newValue.width - currentSize.width) > 10 || abs(newValue.height - currentSize.height) > 10 {
                    currentSize = newValue
                    // Regenerate pixels for new size, but maintain intensity ratio
                    regeneratePixelsForNewSize()
                }
            }
            .onAppear {
                currentSize = geometry.size
                lastIntensity = intensity
                updateBlackedPixels(oldIntensity: 0.0, newIntensity: intensity)
            }
        }
        .ignoresSafeArea()
    }
    
    private func gridKey(for position: CGPoint) -> String {
        // Quantize position to grid to prevent overlaps
        let gridX = Int(position.x / pixelSize)
        let gridY = Int(position.y / pixelSize)
        return "\(gridX),\(gridY)"
    }
    
    private func calculateMaxPixels() -> Int {
        guard currentSize.width > 0 && currentSize.height > 0 else { return 0 }
        // At 100% intensity, we want 100% coverage
        // Calculate total grid positions
        let gridWidth = Int(currentSize.width / pixelSize)
        let gridHeight = Int(currentSize.height / pixelSize)
        return gridWidth * gridHeight
    }
    
    private func regeneratePixelsForNewSize() {
        let maxPixels = calculateMaxPixels()
        let targetCount = Int(intensity * Double(maxPixels))
        blackedPixels = []
        occupiedPositions = []
        
        // Regenerate all pixels for new size
        for _ in 0..<targetCount {
            if let position = findUnoccupiedPosition() {
                blackedPixels.append((id: UUID(), position: position))
                occupiedPositions.insert(gridKey(for: position))
            }
        }
    }
    
    private func findUnoccupiedPosition() -> CGPoint? {
        guard currentSize.width > 0 && currentSize.height > 0 else { return nil }
        
        // Calculate grid dimensions
        let gridWidth = Int(currentSize.width / pixelSize)
        let gridHeight = Int(currentSize.height / pixelSize)
        let totalPositions = gridWidth * gridHeight
        
        // If we've filled all positions, return nil
        if occupiedPositions.count >= totalPositions {
            return nil
        }
        
        // Try to find an unoccupied position (with a limit to prevent infinite loops)
        var attempts = 0
        let maxAttempts = totalPositions * 2
        
        while attempts < maxAttempts {
            let gridX = Int.random(in: 0..<gridWidth)
            let gridY = Int.random(in: 0..<gridHeight)
            let key = "\(gridX),\(gridY)"
            
            if !occupiedPositions.contains(key) {
                // Convert grid position back to screen coordinates
                let x = CGFloat(gridX) * pixelSize + pixelSize / 2
                let y = CGFloat(gridY) * pixelSize + pixelSize / 2
                return CGPoint(x: x, y: y)
            }
            
            attempts += 1
        }
        
        // Fallback: return nil if we can't find a spot (shouldn't happen if logic is correct)
        return nil
    }
    
    private func updateBlackedPixels(oldIntensity: Double, newIntensity: Double) {
        guard currentSize.width > 0 && currentSize.height > 0 else { return }
        
        if newIntensity <= 0 {
            blackedPixels = []
            occupiedPositions = []
            lastIntensity = 0.0
            return
        }
        
        // If intensity changed significantly (more than 20%), regenerate from scratch
        // This ensures manual control works properly
        let intensityDelta = abs(newIntensity - oldIntensity)
        if intensityDelta > 0.2 || oldIntensity == 0.0 {
            regeneratePixelsForIntensity(newIntensity)
            lastIntensity = newIntensity
            return
        }
        
        let maxPixels = calculateMaxPixels()
        let targetCount = Int(newIntensity * Double(maxPixels))
        let currentCount = blackedPixels.count
        
        if targetCount > currentCount {
            // Add pixels if intensity increased
            let toAdd = min(targetCount - currentCount, 500)
            for _ in 0..<toAdd {
                if let position = findUnoccupiedPosition() {
                    blackedPixels.append((id: UUID(), position: position))
                    occupiedPositions.insert(gridKey(for: position))
                } else {
                    break
                }
            }
        } else if targetCount < currentCount {
            // Remove pixels if intensity decreased
            let toRemove = currentCount - targetCount
            // Remove from the end (most recently added)
            blackedPixels.removeLast(min(toRemove, blackedPixels.count))
            // Rebuild occupied positions from remaining pixels
            occupiedPositions = Set(blackedPixels.map { gridKey(for: $0.position) })
        }
        
        lastIntensity = newIntensity
    }
    
    private func regeneratePixelsForIntensity(_ targetIntensity: Double) {
        let maxPixels = calculateMaxPixels()
        let targetCount = Int(targetIntensity * Double(maxPixels))
        blackedPixels = []
        occupiedPositions = []
        
        for _ in 0..<targetCount {
            if let position = findUnoccupiedPosition() {
                blackedPixels.append((id: UUID(), position: position))
                occupiedPositions.insert(gridKey(for: position))
            } else {
                break
            }
        }
    }
}

// MARK: - Sleepy Emoji Mode
struct SleepyEmojiView: View {
    @Binding var intensity: Double
    @State private var emojis: [(id: UUID, position: CGPoint, emoji: String)] = []
    @State private var currentSize: CGSize = .zero
    
    private let sleepyEmojis = ["😴", "💤", "😪", "🥱", "😵", "🛌"]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(emojis, id: \.id) { emojiData in
                    Text(emojiData.emoji)
                        .font(.system(size: 40 + intensity * 40))
                        .position(emojiData.position)
                }
            }
            .onChange(of: intensity) { oldValue, newValue in
                currentSize = geometry.size
                updateEmojis()
            }
            .onChange(of: geometry.size) { oldValue, newValue in
                currentSize = newValue
                updateEmojis()
            }
            .onAppear {
                currentSize = geometry.size
                updateEmojis()
            }
        }
        .ignoresSafeArea()
    }
    
    private func updateEmojis() {
        guard currentSize.width > 0 && currentSize.height > 0 else { return }
        guard intensity > 0 else {
            emojis = []
            return
        }
        
        let targetCount = Int(intensity * 150) // Max 150 emojis
        let currentCount = emojis.count
        
        if targetCount > currentCount {
            let toAdd = targetCount - currentCount
            for _ in 0..<toAdd {
                let x = CGFloat.random(in: 0..<currentSize.width)
                let y = CGFloat.random(in: 0..<currentSize.height)
                let emoji = sleepyEmojis.randomElement() ?? "😴"
                emojis.append((id: UUID(), position: CGPoint(x: x, y: y), emoji: emoji))
            }
        } else if targetCount < currentCount {
            // Remove emojis when intensity decreases
            let toRemove = currentCount - targetCount
            emojis.removeFirst(min(toRemove, 50))
        }
    }
}

// MARK: - Distortion Mode
struct DistortionView: View {
    @Binding var intensity: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background darkening
                Rectangle()
                    .fill(Color.black.opacity(intensity * 0.4))
                
                // Multiple distortion layers - more layers for stronger effect
                ForEach(0..<max(1, Int(intensity * 25)), id: \.self) { index in
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
                // Create wavy distortion effect - much stronger
                let waveCount = 3.0 + intensity * 20.0 // More waves
                let amplitude = intensity * 150.0 // Much larger amplitude (was 80)
                let phaseOffset = Double(index) * 0.8 // More variation between layers
                
                // Draw multiple wavy lines across the screen
                for lineIndex in 0..<5 {
                    var path = Path()
                    let linePhase = phaseOffset + Double(lineIndex) * 0.3
                    
                    for y in stride(from: 0, through: size.height, by: 4) {
                        // Horizontal wave
                        let waveX = sin((Double(y) / size.height) * waveCount * .pi * 2.0 + linePhase) * amplitude
                        let x = size.width / 2.0 + waveX
                        
                        // Also add vertical wave component for more distortion
                        let waveY = cos((Double(y) / size.height) * waveCount * .pi * 1.5 + linePhase) * amplitude * 0.3
                        let finalY = y + waveY
                        
                        if y == 0 {
                            path.move(to: CGPoint(x: x, y: finalY))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: finalY))
                        }
                    }
                    
                    // Draw with varying colors and opacity for more visibility
                    let opacity = 0.6 + (Double(index + lineIndex) * 0.05).truncatingRemainder(dividingBy: 0.4)
                    let colorIndex = (index + lineIndex) % 3
                    let color: Color = colorIndex == 0 ? .cyan : (colorIndex == 1 ? .white : .blue)
                    context.stroke(path, with: .color(color.opacity(opacity)), lineWidth: 2 + intensity * 3)
                }
            }
        }
        .blur(radius: intensity * 60) // More blur for stronger effect
        .opacity(intensity * 0.9) // More visible
    }
}

// MARK: - Messages Mode
struct MessagesView: View {
    @Binding var intensity: Double
    @State private var messages: [(id: UUID, text: String, position: CGPoint)] = []
    @State private var currentSize: CGSize = .zero
    
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
                        .font(.system(size: 28 + intensity * 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(8)
                        .position(message.position)
                }
            }
            .onChange(of: intensity) { oldValue, newValue in
                currentSize = geometry.size
                updateMessages()
            }
            .onChange(of: geometry.size) { oldValue, newValue in
                currentSize = newValue
                updateMessages()
            }
            .onAppear {
                currentSize = geometry.size
                updateMessages()
            }
        }
        .ignoresSafeArea()
    }
    
    private func updateMessages() {
        guard currentSize.width > 0 && currentSize.height > 0 else { return }
        guard intensity > 0 else {
            messages = []
            return
        }
        
        let targetCount = Int(intensity * 20) // Max 20 messages
        let currentCount = messages.count
        
        if targetCount > currentCount {
            let toAdd = targetCount - currentCount
            for _ in 0..<toAdd {
                let x = CGFloat.random(in: 100..<max(200, currentSize.width - 100))
                let y = CGFloat.random(in: 100..<max(200, currentSize.height - 100))
                let text = messageTexts.randomElement() ?? "Go to bed"
                messages.append((id: UUID(), text: text, position: CGPoint(x: x, y: y)))
            }
        } else if targetCount < currentCount {
            // Remove messages when intensity decreases
            let toRemove = currentCount - targetCount
            messages.removeFirst(min(toRemove, 10))
        }
    }
}

// MARK: - Side Swipe Mode
struct SideSwipeView: View {
    @Binding var intensity: Double
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                Spacer()
                
                // Rainbow gradient swipe - comes from right to left
                LinearGradient(
                    colors: [
                        .red, .orange, .yellow, .green, .blue, .indigo, .purple
                    ],
                    startPoint: .trailing,
                    endPoint: .leading
                )
                .frame(width: geometry.size.width * intensity)
                .opacity(0.7 + intensity * 0.3)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
    }
}

