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
            switch blurManager.resolvedMode {
            case .random:
                // This shouldn't happen, but fallback to blur
                BlurOverlayContainer(blurIntensity: intensityBinding)
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
                // Base blur layer - gradually increases from 0
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .blur(radius: blurIntensity * 50)
                    .opacity(blurIntensity)
                
                // Additional blur layers for stronger effect at higher intensities
                // Use continuous scaling instead of discrete steps
                let additionalLayers = max(0, Int(blurIntensity * 8)) // Up to 8 layers
                ForEach(0..<additionalLayers, id: \.self) { index in
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .blur(radius: blurIntensity * 40 + Double(index) * 10)
                        .opacity(blurIntensity * 0.7)
                }
                
                // Darkening layer - gradually increases
                Rectangle()
                    .fill(Color.black.opacity(blurIntensity * 0.5))
                
                // NSVisualEffectView layers - start appearing earlier and scale continuously
                let effectLayerCount = max(0, Int(blurIntensity * 4)) // Up to 4 layers, starts at 25% intensity
                ForEach(0..<effectLayerCount, id: \.self) { _ in
                    BlurOverlayView(blurIntensity: Binding(
                        get: { blurIntensity },
                        set: { blurIntensity = $0 }
                    ))
                    .opacity(blurIntensity * 0.8)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
    }
}

