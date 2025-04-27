import Foundation
import SwiftData

enum ActivityMode: String, Codable {
    case duration
    case count
}

@Model
final class Activity {
    var id: UUID
    var name: String
    var mode: ActivityMode
    var timeSpent: TimeInterval
    var count: Int
    var date: Date
    
    init(id: UUID = UUID(), name: String, mode: ActivityMode, timeSpent: TimeInterval = 0, count: Int = 0, date: Date) {
        self.id = id
        self.name = name
        self.mode = mode
        self.timeSpent = timeSpent
        self.count = count
        self.date = date
    }
    
    var formattedValue: String {
        switch mode {
        case .duration:
            let hours = Int(timeSpent) / 3600
            let minutes = (Int(timeSpent) % 3600) / 60
            if hours > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(minutes)m"
            }
        case .count:
            return "\(count)"
        }
    }
} 