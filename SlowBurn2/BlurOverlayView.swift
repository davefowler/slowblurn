import SwiftUI
import AppKit

// Wrapper view that observes BlurManager to ensure updates propagate
struct OverlayWrapperView: View {
    @ObservedObject var blurManager: BlurManager
    
    var body: some View {
        // Create a binding to intensity for use in SwiftUI views
        let intensityBinding = Binding<Double>(
            get: { blurManager.intensity },
            set: { blurManager.intensity = $0 }
        )
        
        Group {
            switch blurManager.selectedMode {
            case .blur:
                BlurOverlayContainer(blurIntensity: intensityBinding)
            case .confetti:
                ConfettiView(intensity: intensityBinding)
            case .pixelFreeze:
                PixelFreezeView(intensity: intensityBinding)
            case .pixelBlackout:
                PixelBlackoutView(intensity: intensityBinding)
            case .sleepyEmoji:
                SleepyEmojiView(intensity: intensityBinding)
            case .distortion:
                DistortionView(intensity: intensityBinding)
            case .messages:
                MessagesView(intensity: intensityBinding)
            case .sideSwipe:
                SideSwipeView(intensity: intensityBinding)
            }
        }
    }
}

struct BlurOverlayView: NSViewRepresentable {
    @Binding var blurIntensity: Double
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .sidebar
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        // Use stronger blur materials as intensity increases
        if blurIntensity > 0.8 {
            nsView.material = .sidebar // Strongest blur material
        } else if blurIntensity > 0.5 {
            nsView.material = .popover
        } else if blurIntensity > 0.2 {
            nsView.material = .hudWindow
        } else {
            nsView.material = .underWindowBackground
        }
        
        // Increase opacity for stronger effect - make it more visible
        nsView.alphaValue = CGFloat(min(blurIntensity * 1.5, 1.0))
    }
}

struct BlurOverlayContainer: View {
    @Binding var blurIntensity: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Use SwiftUI's blur modifier - scaled more gradually
                // Create layers with increasing blur radius, but scale down the intensity
                let blurRadius = blurIntensity * 30 // Max 30 point blur (was 100)
                let layerCount = max(1, Int(blurIntensity * 5)) // Max 5 layers (was 20)
                
                ForEach(0..<layerCount, id: \.self) { index in
                    Rectangle()
                        .fill(Color.white.opacity(0.05))
                        .blur(radius: blurRadius / Double(layerCount) * Double(index + 1))
                        .opacity(blurIntensity) // Linear opacity scaling
                }
                
                // Additional darkening layer - much more gradual
                Rectangle()
                    .fill(Color.black.opacity(blurIntensity * 0.3)) // Was 0.8
                
                // Extra blur layers using NSVisualEffectView - only at higher intensities
                if blurIntensity > 0.6 {
                    let effectLayerCount = Int((blurIntensity - 0.6) * 2.5) // Only 0-1 layers between 60-100%
                    ForEach(0..<effectLayerCount, id: \.self) { _ in
                        BlurOverlayView(blurIntensity: Binding(
                            get: { blurIntensity },
                            set: { blurIntensity = $0 }
                        ))
                        .opacity(blurIntensity)
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
    }
}

