import Foundation

enum ModeType: String, CaseIterable, Identifiable {
    case random = "Random"
    case blur = "Blur"
    case confetti = "Confetti"
    case pixelFreeze = "Pixel Freeze"
    case pixelBlackout = "Pixel Blackout"
    case sleepyEmoji = "Sleepy Emoji"
    case distortion = "Distortion"
    case messages = "Messages"
    case sideSwipe = "Side Swipe"
    
    var id: String { rawValue }
    
    // All modes except Random
    static var nonRandomModes: [ModeType] {
        return [.blur, .confetti, .pixelFreeze, .pixelBlackout, .sleepyEmoji, .distortion, .messages, .sideSwipe]
    }
    
    // Get a random mode based on the day (consistent for the entire day)
    static func randomModeForToday() -> ModeType {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: today) ?? 0
        
        // Use day of year as seed to get consistent mode for the day
        let modes = nonRandomModes
        let index = dayOfYear % modes.count
        return modes[index]
    }
    
    var description: String {
        switch self {
        case .random:
            return "Picks a different mode each day"
        case .blur:
            return "Gradual blur effect"
        case .confetti:
            return "Colorful confetti overlay"
        case .pixelFreeze:
            return "Freeze pixels with their actual colors"
        case .pixelBlackout:
            return "Randomly black out pixels"
        case .sleepyEmoji:
            return "Cover screen with sleepy emojis"
        case .distortion:
            return "Funky distortion overlay"
        case .messages:
            return "Fill screen with bedtime messages"
        case .sideSwipe:
            return "Rainbow swipe from right to left"
        }
    }
}

enum AccelerationCurve: String, CaseIterable, Identifiable {
    case linear = "Linear"
    case exponential = "Exponential"
    case logarithmic = "Logarithmic"
    
    var id: String { rawValue }
    
    func apply(_ progress: Double) -> Double {
        // progress is 0.0 to 1.0
        switch self {
        case .linear:
            return progress
        case .exponential:
            // Starts slow, accelerates rapidly at the end
            return progress < 0.0 ? 0.0 : pow(2.0, 10.0 * (progress - 1.0))
        case .logarithmic:
            // Starts fast, slows down at the end (inverse of exponential)
            if progress <= 0.0 {
                return 0.0
            } else if progress >= 1.0 {
                return 1.0
            } else {
                // Logarithmic curve: log10(1 + 9 * progress) / log10(10)
                return log10(1.0 + 9.0 * progress) / log10(10.0)
            }
        }
    }
}

