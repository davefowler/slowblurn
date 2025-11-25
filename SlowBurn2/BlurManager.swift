import SwiftUI
import AppKit
import Combine

class BlurManager: ObservableObject {
    static let shared = BlurManager()
    
    @Published var intensity: Double = 0.0
    @Published var selectedMode: ModeType = .random
    @Published var accelerationCurve: AccelerationCurve = .linear
    
    // Resolve random mode to actual mode for today
    var resolvedMode: ModeType {
        if selectedMode == .random {
            return ModeType.randomModeForToday()
        }
        return selectedMode
    }
    @Published var startHour: Int = 21 // 9pm
    @Published var startMinute: Int = 0
    @Published var endHour: Int = 22 // 10pm
    @Published var endMinute: Int = 0
    @Published var scheduleEnabled: Bool = true
    @Published var enabledDays: Set<Int> = [0, 1, 2, 3, 4, 5, 6] // Sunday = 0, Monday = 1, ..., Saturday = 6
    
    private var overlayWindow: NSWindow?
    private var timer: Timer?
    private var testTimer: Timer?
    private var isTesting: Bool = false
    private var testStartTime: Date?
    @Published var isManualMode: Bool = false
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupOverlayWindow()
        startMonitoring()
        
        // Restart monitoring when start/end times change to recalculate update interval
        $startHour.sink { [weak self] _ in self?.restartMonitoring() }.store(in: &cancellables)
        $startMinute.sink { [weak self] _ in self?.restartMonitoring() }.store(in: &cancellables)
        $endHour.sink { [weak self] _ in self?.restartMonitoring() }.store(in: &cancellables)
        $endMinute.sink { [weak self] _ in self?.restartMonitoring() }.store(in: &cancellables)
    }
    
    private func restartMonitoring() {
        timer?.invalidate()
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
        
        // Create a wrapper view that observes this BlurManager to ensure updates
        let wrapperView = OverlayWrapperView(blurManager: self)
        window.contentView = NSHostingView(rootView: wrapperView)
    }
    
    private func startMonitoring() {
        // Calculate update interval to get exactly 600 updates between start and end time
        let startMinutes = startHour * 60 + startMinute
        let endMinutes = endHour * 60 + endMinute
        let durationMinutes = Double(endMinutes - startMinutes)
        
        // If duration is 0 or negative, use a default interval
        let updateInterval: TimeInterval
        if durationMinutes > 0 {
            // 600 updates over the duration (convert minutes to seconds)
            updateInterval = (durationMinutes * 60.0) / 600.0
        } else {
            // Default to checking every 6 seconds if duration is invalid
            updateInterval = 6.0
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.updateIntensity()
        }
        // Add to common run loop mode so it fires even during UI interactions
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
        updateIntensity()
    }
    
    private func updateIntensity() {
        // Don't update if we're in test mode or manual mode
        guard !isTesting && !isManualMode else { return }
        
        // Check if schedule is enabled
        guard scheduleEnabled else {
            intensity = 0.0
            overlayWindow?.orderOut(nil)
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.weekday, .hour, .minute], from: now)
        
        guard let weekday = components.weekday, let hour = components.hour, let minute = components.minute else { return }
        
        // weekday is 1-7 (Sunday = 1, Monday = 2, ..., Saturday = 7)
        // Convert to 0-6 (Sunday = 0, Monday = 1, ..., Saturday = 6)
        let dayOfWeek = (weekday - 1) % 7
        
        // Check if today is an enabled day
        guard enabledDays.contains(dayOfWeek) else {
            intensity = 0.0
            overlayWindow?.orderOut(nil)
            return
        }
        
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
        isManualMode = false // Exit manual mode for test
        intensity = 0.0
        isTesting = true
        testStartTime = Date()
        updateOverlayView()
        overlayWindow?.orderFront(nil)
        
        // Animate intensity from 0 to 1 over 30 seconds
        let duration: TimeInterval = 30.0
        let updateInterval: TimeInterval = 0.05 // Update 20 times per second for smooth animation
        
        // Create timer on main run loop to ensure UI updates work
        testTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] timer in
            guard let self = self,
                  let startTime = self.testStartTime else {
                timer.invalidate()
                return
            }
            
            let elapsed = Date().timeIntervalSince(startTime)
            let progress = min(elapsed / duration, 1.0)
            
            // Apply the selected acceleration curve to the progress
            // Update on main thread to ensure SwiftUI updates
            DispatchQueue.main.async {
                self.intensity = self.accelerationCurve.apply(progress)
            }
            
            // When test is complete, reset and resume normal monitoring
            if progress >= 1.0 {
                timer.invalidate()
                DispatchQueue.main.async {
                    self.testTimer = nil
                    self.isTesting = false
                    self.testStartTime = nil
                    // Resume normal intensity updates
                    self.updateIntensity()
                }
            }
        }
        
        // Ensure timer fires even when scrolling/interacting
        RunLoop.main.add(testTimer!, forMode: .common)
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

