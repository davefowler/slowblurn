import SwiftUI
import AppKit
import Combine

class BlurManager: ObservableObject {
    static let shared = BlurManager()
    
    @Published var intensity: Double = 0.0
    @Published var selectedMode: ModeType = .blur
    @Published var accelerationCurve: AccelerationCurve = .easeInOut
    @Published var startHour: Int = 21 // 9pm
    @Published var startMinute: Int = 0
    @Published var endHour: Int = 22 // 10pm
    @Published var endMinute: Int = 0
    
    private var overlayWindow: NSWindow?
    private var timer: Timer?
    private var testTimer: Timer?
    private var isTesting: Bool = false
    private var testStartTime: Date?
    @Published var isManualMode: Bool = false
    
    init() {
        setupOverlayWindow()
        startMonitoring()
    }
    
    private func setupOverlayWindow() {
        // Get the frame that covers all screens
        var totalFrame = CGRect.zero
        for screen in NSScreen.screens {
            totalFrame = totalFrame.union(screen.frame)
        }
        
        // Create a borderless, fullscreen window covering all screens
        let window = NSWindow(
            contentRect: totalFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Use .screenSaver level to ensure it's above everything
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.ignoresMouseEvents = true // Allow clicks to pass through
        window.hasShadow = false
        window.acceptsMouseMovedEvents = false
        window.isReleasedWhenClosed = false
        
        // Create the mode view based on selected mode
        updateOverlayView()
        
        overlayWindow = window
        
        // Make sure window is initially hidden (will show when intensity > 0)
        window.orderOut(nil)
    }
    
    private func updateOverlayView() {
        guard let window = overlayWindow else { return }
        
        // Create a binding to intensity for use in SwiftUI views
        let intensityBinding = Binding<Double>(
            get: { self.intensity },
            set: { self.intensity = $0 }
        )
        
        let contentView: AnyView
        switch selectedMode {
        case .blur:
            contentView = AnyView(BlurOverlayContainer(blurIntensity: intensityBinding))
        case .pixel:
            contentView = AnyView(PixelFreezeView(intensity: intensityBinding))
        case .pixelBlackout:
            contentView = AnyView(PixelBlackoutView(intensity: intensityBinding))
        case .sleepyEmoji:
            contentView = AnyView(SleepyEmojiView(intensity: intensityBinding))
        case .distortion:
            contentView = AnyView(DistortionView(intensity: intensityBinding))
        case .messages:
            contentView = AnyView(MessagesView(intensity: intensityBinding))
        case .sideSwipe:
            contentView = AnyView(SideSwipeView(intensity: intensityBinding))
        }
        
        window.contentView = NSHostingView(rootView: contentView)
    }
    
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateIntensity()
        }
        updateIntensity()
    }
    
    private func updateIntensity() {
        // Don't update if we're in test mode or manual mode
        guard !isTesting && !isManualMode else { return }
        
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.hour, .minute], from: now)
        
        guard let hour = components.hour, let minute = components.minute else { return }
        
        // Convert to minutes since midnight for easier calculation
        let currentMinutes = hour * 60 + minute
        let startMinutes = startHour * 60 + startMinute
        let endMinutes = endHour * 60 + endMinute
        
        if currentMinutes < startMinutes {
            // Before start time - no effect
            intensity = 0.0
            overlayWindow?.orderOut(nil)
        } else if currentMinutes >= endMinutes {
            // After end time - maximum intensity
            intensity = 1.0
            overlayWindow?.orderFront(nil)
        } else {
            // Between start and end - gradual progression
            let elapsed = Double(currentMinutes - startMinutes)
            let duration = Double(endMinutes - startMinutes)
            let rawProgress = min(elapsed / duration, 1.0)
            
            // Apply acceleration curve
            intensity = accelerationCurve.apply(rawProgress)
            overlayWindow?.orderFront(nil)
        }
    }
    
    func showWindow() {
        updateOverlayView()
        overlayWindow?.orderFront(nil)
    }
    
    func hideWindow() {
        overlayWindow?.orderOut(nil)
    }
    
    func setMode(_ mode: ModeType) {
        selectedMode = mode
        updateOverlayView()
    }
    
    func testEffect() {
        // Stop any existing test
        testTimer?.invalidate()
        testTimer = nil
        
        // Reset intensity and show window
        intensity = 0.0
        isTesting = true
        testStartTime = Date()
        updateOverlayView()
        overlayWindow?.orderFront(nil)
        
        // Animate intensity from 0 to 1 over 30 seconds
        let duration: TimeInterval = 30.0
        let updateInterval: TimeInterval = 0.05 // Update 20 times per second for smooth animation
        
        testTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] timer in
            guard let self = self,
                  let startTime = self.testStartTime else {
                timer.invalidate()
                return
            }
            
            let elapsed = Date().timeIntervalSince(startTime)
            let progress = min(elapsed / duration, 1.0)
            
            // Apply the selected acceleration curve to the progress
            self.intensity = self.accelerationCurve.apply(progress)
            
            // When test is complete, reset and resume normal monitoring
            if progress >= 1.0 {
                timer.invalidate()
                self.testTimer = nil
                self.isTesting = false
                self.testStartTime = nil
                // Resume normal intensity updates
                self.updateIntensity()
            }
        }
    }
    
    func setManualIntensity(_ value: Double) {
        isManualMode = true
        intensity = max(0.0, min(1.0, value))
        updateOverlayView() // Make sure view is updated
        if intensity > 0 {
            overlayWindow?.orderFront(nil)
        } else {
            overlayWindow?.orderOut(nil)
        }
    }
    
    func resumeAutomaticMode() {
        isManualMode = false
        updateIntensity()
    }
}

