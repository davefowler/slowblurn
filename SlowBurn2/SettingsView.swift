import SwiftUI
import AppKit

struct SettingsView: View {
    @EnvironmentObject var blurManager: BlurManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Slow Blurn")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Wind down your screen")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Divider()
                
                // Mode Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Mode")
            f            .font(.headline)
                    
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
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
                // Acceleration Curve
                VStack(alignment: .leading, spacing: 12) {
                    Text("Acceleration Curve")
                        .font(.headline)
                    
                    Picker("Curve", selection: $blurManager.accelerationCurve) {
                        ForEach(AccelerationCurve.allCases) { curve in
                            Text(curve.rawValue).tag(curve)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
                // Time Settings
                VStack(alignment: .leading, spacing: 12) {
                    Text("Schedule")
                        .font(.headline)
                    
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
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
                // Status
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Current intensity:")
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(Int(blurManager.intensity * 100))%")
                            .foregroundColor(.secondary)
                            .fontWeight(.bold)
                    }
                    
                    // Manual intensity slider
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Manual Control")
                                .font(.subheadline)
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
                .padding()
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
            .padding(30)
        }
        .frame(width: 450, height: 600)
    }
}

