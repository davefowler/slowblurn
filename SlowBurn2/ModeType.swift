import Foundation

enum ModeType: String, CaseIterable, Identifiable {
    case blur = "Blur"
    case pixel = "Pixel Freeze"
    case pixelBlackout = "Pixel Blackout"
    case sleepyEmoji = "Sleepy Emoji"
    case distortion = "Distortion"
    case messages = "Messages"
    case sideSwipe = "Side Swipe"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .blur:
            return "Gradual blur effect"
        case .pixel:
            return "Randomly freeze pixels"
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
    case easeIn = "Ease In"
    case easeOut = "Ease Out"
    case easeInOut = "Ease In/Out"
    case exponential = "Exponential"
    
    var id: String { rawValue }
    
    func apply(_ progress: Double) -> Double {
        // progress is 0.0 to 1.0
        switch self {
        case .linear:
            return progress
        case .easeIn:
            return progress * progress
        case .easeOut:
            return 1.0 - (1.0 - progress) * (1.0 - progress)
        case .easeInOut:
            return progress < 0.5
                ? 2.0 * progress * progress
                : 1.0 - pow(-2.0 * progress + 2.0, 2.0) / 2.0
        case .exponential:
            return progress < 0.0 ? 0.0 : pow(2.0, 10.0 * (progress - 1.0))
        }
    }
}

