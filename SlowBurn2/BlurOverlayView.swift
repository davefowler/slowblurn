import SwiftUI
import AppKit

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
                // DEBUG: Red overlay to verify window is visible
                Rectangle()
                    .fill(Color.red.opacity(blurIntensity * 0.5))
                
                // DEBUG: Large text to verify window is there
                VStack {
                    Text("BLUR OVERLAY ACTIVE")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundColor(.white)
                    Text("Intensity: \(Int(blurIntensity * 100))%")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.yellow)
                }
                
                // Use SwiftUI's blur modifier which works better for overlays
                // Create multiple layers with increasing blur radius
                let blurRadius = blurIntensity * 100 // Max 100 point blur
                let layerCount = max(1, Int(blurIntensity * 20))
                
                ForEach(0..<layerCount, id: \.self) { index in
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .blur(radius: blurRadius / Double(layerCount) * Double(index + 1))
                        .opacity(min(blurIntensity * 1.5, 1.0))
                }
                
                // Additional darkening layer - starts earlier and gets stronger
                Rectangle()
                    .fill(Color.black.opacity(blurIntensity * 0.8))
                
                // Extra blur layers using NSVisualEffectView for additional effect
                if blurIntensity > 0.3 {
                    let effectLayerCount = Int(blurIntensity * 10)
                    ForEach(0..<effectLayerCount, id: \.self) { _ in
                        BlurOverlayView(blurIntensity: Binding(
                            get: { blurIntensity },
                            set: { blurIntensity = $0 }
                        ))
                        .opacity(min(blurIntensity * 1.2, 1.0))
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
    }
}

