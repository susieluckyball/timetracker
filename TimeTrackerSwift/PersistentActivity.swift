import Foundation
import SwiftData

@Model
final class PersistentActivity {
    var name: String
    var startTime: Date
    var isActive: Bool
    var timeSpent: TimeInterval
    
    init(name: String, startTime: Date = Date(), isActive: Bool = false, timeSpent: TimeInterval) {
        self.name = name
        self.startTime = startTime
        self.isActive = isActive
        self.timeSpent = timeSpent
    }
    
    var duration: TimeInterval {
        return timeSpent
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

extension PersistentActivity: Hashable {
    static func == (lhs: PersistentActivity, rhs: PersistentActivity) -> Bool {
        lhs.name == rhs.name && 
        Calendar.current.isDate(lhs.startTime, inSameDayAs: rhs.startTime)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(Calendar.current.startOfDay(for: startTime))
    }
} 
