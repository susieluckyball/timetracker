import Foundation
import SwiftData

@Model
final class PersistentActivity {
    var id: UUID
    var name: String
    var startTime: Date
    var isActive: Bool
    var timeSpent: TimeInterval
    
    init(id: UUID = UUID(), name: String, startTime: Date = Date(), isActive: Bool = false, timeSpent: TimeInterval = 0) {
        self.id = id
        self.name = name
        self.startTime = startTime
        self.isActive = isActive
        self.timeSpent = timeSpent
    }
    
    var duration: TimeInterval {
        if isActive {
            return Date().timeIntervalSince(startTime)
        }
        return timeSpent
    }
    
    // Convert to regular Activity
    func toActivity() -> Activity {
        return Activity(id: id, name: name, timeSpent: timeSpent, date: startTime)
    }
    
    // Create from regular Activity
    static func fromActivity(_ activity: Activity) -> PersistentActivity {
        return PersistentActivity(id: activity.id, name: activity.name, startTime: activity.date, timeSpent: activity.timeSpent)
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