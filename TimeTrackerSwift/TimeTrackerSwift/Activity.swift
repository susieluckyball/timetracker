import Foundation

struct Activity: Identifiable, Codable {
    let id: UUID
    let name: String
    var timeSpent: TimeInterval
    var date: Date
    
    init(id: UUID = UUID(), name: String, timeSpent: TimeInterval, date: Date) {
        self.id = id
        self.name = name
        self.timeSpent = timeSpent
        self.date = date
    }
    
    var formattedTime: String {
        let hours = Int(timeSpent) / 3600
        let minutes = (Int(timeSpent) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
} 