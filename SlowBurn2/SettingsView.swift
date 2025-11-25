import SwiftUI
import AppKit

struct SettingsView: View {
    @EnvironmentObject var blurManager: BlurManager
    
    private var accelerationCurveDescription: String {
        switch blurManager.accelerationCurve {
        case .linear:
            return "Constant rate of change"
        case .exponential:
            return "Slow start, fast end"
        case .logarithmic:
            return "Fast start, slow end"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Header - icon and title inline
                HStack(spacing: 12) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Slow Blurn")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Wind down your screen")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 4)
                
                Divider()
                
                // Mode and Acceleration Curve - side by side
                HStack(spacing: 12) {
                    // Mode Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mode")
                            .font(.headline)
                        
                        Picker("Mode", selection: $blurManager.selectedMode) {
                            ForEach(ModeType.allCases) { mode in
                                    Text(mode.rawValue)
                                        .tag(mode)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: blurManager.selectedMode) { oldValue, newValue in
                            blurManager.setMode(newValue)
                        }
                        
                        Text(blurManager.selectedMode.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity)
                    
                    // Acceleration Curve
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Acceleration Curve")
                            .font(.headline)
                        
                        Picker("Curve", selection: $blurManager.accelerationCurve) {
                            ForEach(AccelerationCurve.allCases) { curve in
                                Text(curve.rawValue).tag(curve)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(accelerationCurveDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity)
                }
                
                // Time Settings
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Schedule")
                            .font(.headline)
                        Spacer()
                        Toggle("", isOn: $blurManager.scheduleEnabled)
                            .labelsHidden()
                    }
                    
                    HStack {
                        Text("Starts at:")
                            .fontWeight(.medium)
                        Spacer()
                        HStack {
                            Picker("Hour", selection: $blurManager.startHour) {
                                ForEach(0..<24) { hour in
                                    Text("\(hour):00").tag(hour)
                                }
                            }
                            .frame(width: 80)
                            
                            Picker("Minute", selection: $blurManager.startMinute) {
                                ForEach([0, 15, 30, 45], id: \.self) { minute in
                                    Text(":\(String(format: "%02d", minute))").tag(minute)
                                }
                            }
                            .frame(width: 60)
                        }
                    }
                    
                    HStack {
                        Text("Maximum at:")
                            .fontWeight(.medium)
                        Spacer()
                        HStack {
                            Picker("Hour", selection: $blurManager.endHour) {
                                ForEach(0..<24) { hour in
                                    Text("\(hour):00").tag(hour)
                                }
                            }
                            .frame(width: 80)
                            
                            Picker("Minute", selection: $blurManager.endMinute) {
                                ForEach([0, 15, 30, 45], id: \.self) { minute in
                                    Text(":\(String(format: "%02d", minute))").tag(minute)
                                }
                            }
                            .frame(width: 60)
                        }
                    }
                    
                    // Days of the week checkboxes
                    HStack(spacing: 8) {
                        ForEach(0..<7) { dayIndex in
                            let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
                            Button(action: {
                                if blurManager.enabledDays.contains(dayIndex) {
                                    blurManager.enabledDays.remove(dayIndex)
                                } else {
                                    blurManager.enabledDays.insert(dayIndex)
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: blurManager.enabledDays.contains(dayIndex) ? "checkmark.square.fill" : "square")
                                        .foregroundColor(blurManager.enabledDays.contains(dayIndex) ? .blue : .secondary)
                                    Text(dayLabels[dayIndex])
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
                // Status
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Current intensity:")
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(Int(blurManager.intensity * 100))%")
                            .foregroundColor(.secondary)
                            .fontWeight(.bold)
                    }
                    
                    // Manual intensity slider
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Manual Control")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            if blurManager.isManualMode {
                                Button("Resume Auto") {
                                    blurManager.resumeAutomaticMode()
                                }
                                .buttonStyle(.borderless)
                                .font(.caption)
                            }
                        }
                        
                        Slider(value: Binding(
                            get: { blurManager.intensity },
                            set: { blurManager.setManualIntensity($0) }
                        ), in: 0...1)
                        .onChange(of: blurManager.intensity) { oldValue, newValue in
                            // When slider changes, ensure we're in manual mode
                            if !blurManager.isManualMode {
                                blurManager.isManualMode = true
                            }
                        }
                        
                        HStack {
                            Text("0%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("100%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Progress view for visual reference
                    ProgressView(value: blurManager.intensity)
                        .opacity(0.5)
                }
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
                // Actions
                HStack(spacing: 12) {
                    Button("Test Effect") {
                        blurManager.testEffect()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Quit App") {
                        NSApplication.shared.terminate(nil)
                    }
                    .buttonStyle(.bordered)
                }
                
                Text("The app runs in the background.\nClose this window to keep it running.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
        }
        .frame(width: 450, height: 550)
    }
}

