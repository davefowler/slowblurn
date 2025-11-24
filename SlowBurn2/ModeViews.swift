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

// MARK: - Pixel Freeze Mode (captures actual screen colors)
struct PixelFreezeView: View {
    @Binding var intensity: Double
    @State private var frozenPixels: [(id: UUID, position: CGPoint, color: Color)] = []
    @State private var occupiedPositions: Set<String> = []
    @State private var currentSize: CGSize = .zero
    @State private var lastIntensity: Double = 0.0
    @State private var screenImage: NSImage?
    
    private let pixelSize: CGFloat = 5
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Frozen pixels with their actual screen colors
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
                captureScreen()
                updateFrozenPixels(oldIntensity: 0.0, newIntensity: intensity)
            }
        }
        .ignoresSafeArea()
    }
    
    private func captureScreen() {
        // Capture all screens
        var totalRect = CGRect.zero
        for screen in NSScreen.screens {
            totalRect = totalRect.union(screen.frame)
        }
        
        // Capture screen content (what's behind our overlay)
        // Use optionOnScreenBelowWindow to get content below our overlay window
        if let cgImage = CGWindowListCreateImage(totalRect, .optionOnScreenBelowWindow, kCGNullWindowID, .bestResolution) {
            screenImage = NSImage(cgImage: cgImage, size: totalRect.size)
        }
    }
    
    private func getColorAt(position: CGPoint) -> Color {
        guard let image = screenImage,
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return Color.gray.opacity(0.5) // Fallback color
        }
        
        // Get the image size
        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)
        
        guard imageWidth > 0 && imageHeight > 0 else { return Color.gray.opacity(0.5) }
        
        // Convert view coordinates to image coordinates
        // Need to account for screen origin (usually bottom-left for Core Graphics)
        let screen = NSScreen.main ?? NSScreen.screens.first
        let screenHeight = screen?.frame.height ?? imageHeight
        
        // Convert Y coordinate (SwiftUI uses top-left, CG uses bottom-left)
        let imageX = Int(position.x * (imageWidth / currentSize.width))
        let imageY = Int((screenHeight - position.y) * (imageHeight / screenHeight))
        
        guard imageX >= 0 && imageX < Int(imageWidth) && imageY >= 0 && imageY < Int(imageHeight) else {
            return Color.gray.opacity(0.5)
        }
        
        // Create a bitmap context to read the pixel
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var pixelData: [UInt8] = [0, 0, 0, 255]
        
        guard let context = CGContext(
            data: &pixelData,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return Color.gray.opacity(0.5)
        }
        
        // Draw the image offset so we sample the right pixel
        context.draw(cgImage, in: CGRect(x: -CGFloat(imageX), y: -CGFloat(imageY), width: imageWidth, height: imageHeight))
        
        // Convert to SwiftUI Color (RGBA format)
        let red = Double(pixelData[0]) / 255.0
        let green = Double(pixelData[1]) / 255.0
        let blue = Double(pixelData[2]) / 255.0
        
        return Color(red: red, green: green, blue: blue)
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
        captureScreen() // Re-capture for new size
        let maxPixels = calculateMaxPixels()
        let targetCount = Int(intensity * Double(maxPixels))
        frozenPixels = []
        occupiedPositions = []
        
        for _ in 0..<targetCount {
            if let position = findUnoccupiedPosition() {
                let color = getColorAt(position: position)
                frozenPixels.append((id: UUID(), position: position, color: color))
                occupiedPositions.insert(gridKey(for: position))
            }
        }
    }
    
    private func findUnoccupiedPosition() -> CGPoint? {
        guard currentSize.width > 0 && currentSize.height > 0 else { return nil }
        
        let gridWidth = Int(currentSize.width / pixelSize)
        let gridHeight = Int(currentSize.height / pixelSize)
        let totalPositions = gridWidth * gridHeight
        
        if occupiedPositions.count >= totalPositions {
            return nil
        }
        
        var attempts = 0
        let maxAttempts = totalPositions * 2
        
        while attempts < maxAttempts {
            let gridX = Int.random(in: 0..<gridWidth)
            let gridY = Int.random(in: 0..<gridHeight)
            let key = "\(gridX),\(gridY)"
            
            if !occupiedPositions.contains(key) {
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
            occupiedPositions = []
            lastIntensity = 0.0
            return
        }
        
        // Capture screen periodically to get fresh colors
        if Int(newIntensity * 100) % 10 == 0 && Int(oldIntensity * 100) % 10 != 0 {
            captureScreen()
        }
        
        let maxPixels = calculateMaxPixels()
        let targetCount = Int(newIntensity * Double(maxPixels))
        let currentCount = frozenPixels.count
        
        // Only add pixels if intensity increased - never remove existing pixels
        if targetCount > currentCount {
            let toAdd = min(targetCount - currentCount, 500)
            for _ in 0..<toAdd {
                if let position = findUnoccupiedPosition() {
                    let color = getColorAt(position: position)
                    frozenPixels.append((id: UUID(), position: position, color: color))
                    occupiedPositions.insert(gridKey(for: position))
                } else {
                    break
                }
            }
        }
        
        lastIntensity = newIntensity
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
        
        let maxPixels = calculateMaxPixels()
        let targetCount = Int(newIntensity * Double(maxPixels))
        let currentCount = blackedPixels.count
        
        // Only add pixels if intensity increased - never remove existing pixels
        if targetCount > currentCount {
            let toAdd = min(targetCount - currentCount, 500) // Add up to 500 per update
            for _ in 0..<toAdd {
                if let position = findUnoccupiedPosition() {
                    blackedPixels.append((id: UUID(), position: position))
                    occupiedPositions.insert(gridKey(for: position))
                } else {
                    // No more positions available (should only happen at 100%)
                    break
                }
            }
        }
        // Note: We don't remove pixels when intensity decreases - pixels stay "dead"
        
        lastIntensity = newIntensity
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
                    .fill(Color.black.opacity(intensity * 0.3))
                
                // Multiple distortion layers
                ForEach(0..<max(1, Int(intensity * 15)), id: \.self) { index in
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
                let waveCount = 5.0 + intensity * 15.0
                let amplitude = intensity * 80.0
                
                var path = Path()
                for y in stride(from: 0, through: size.height, by: 8) {
                    let wave = sin((Double(y) / size.height) * waveCount * .pi * 2.0 + Double(index) * 0.5) * amplitude
                    let x = size.width / 2.0 + wave
                    
                    if y == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                
                context.stroke(path, with: .color(.white.opacity(0.5)), lineWidth: 3)
            }
        }
        .blur(radius: intensity * 40)
        .opacity(intensity * 0.8)
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

