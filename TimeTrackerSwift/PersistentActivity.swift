import Foundation
import SwiftData

@Model
final class PersistentActivity {
    var name: String
    var startTime: Date
    var endTime: Date?
    var isActive: Bool
    var timeSpent: TimeInterval?
    
    init(name: String, startTime: Date = Date(), endTime: Date? = nil, isActive: Bool = false, timeSpent: TimeInterval? = nil) {
        self.name = name
        self.startTime = startTime
        self.endTime = endTime
        self.isActive = isActive
        self.timeSpent = timeSpent
    }
    
    var duration: TimeInterval {
        if let timeSpent = timeSpent {
            return timeSpent
        }
        if isActive, let endTime = endTime {
            return endTime.timeIntervalSince(startTime)
        }
        return 0
    }
    
    // Convert to regular Activity
    func toActivity() -> Activity {
        return Activity(id: UUID(), name: name, timeSpent: duration, date: startTime)
    }
    
    // Create from regular Activity
    static func fromActivity(_ activity: Activity) -> PersistentActivity {
        return PersistentActivity(name: activity.name, startTime: activity.date, timeSpent: activity.timeSpent)
    }
} 