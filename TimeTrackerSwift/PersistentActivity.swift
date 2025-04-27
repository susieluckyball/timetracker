import Foundation
import SwiftData

@Model
final class PersistentActivity {
    var id: UUID
    var name: String
    var mode: ActivityMode
    var startTime: Date
    var timeSpent: TimeInterval
    var count: Int
    
    init(id: UUID = UUID(), name: String, mode: ActivityMode, startTime: Date = Date(), timeSpent: TimeInterval = 0, count: Int = 0) {
        self.id = id
        self.name = name
        self.mode = mode
        self.startTime = startTime
        self.timeSpent = timeSpent
        self.count = count
    }
    
    // Convert to regular Activity
    func toActivity() -> Activity {
        return Activity(id: id, name: name, mode: mode, timeSpent: timeSpent, count: count, date: startTime)
    }
    
    // Create from regular Activity
    static func fromActivity(_ activity: Activity) -> PersistentActivity {
        return PersistentActivity(id: activity.id, name: activity.name, mode: activity.mode, startTime: activity.date, timeSpent: activity.timeSpent, count: activity.count)
    }
}

extension PersistentActivity: Hashable {
    static func == (lhs: PersistentActivity, rhs: PersistentActivity) -> Bool {
        // Compare by ID first, then by name and start date if needed
        if lhs.id == rhs.id {
            return true
        }
        
        return lhs.name == rhs.name && 
            Calendar.current.isDate(lhs.startTime, inSameDayAs: rhs.startTime)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(Calendar.current.startOfDay(for: startTime))
    }
}