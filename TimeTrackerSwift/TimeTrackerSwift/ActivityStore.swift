import Foundation
import SwiftUI

struct WeeklyStats {
    let weekStart: Date
    let hours: Double
    let activity: Activity
    
    var weekLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: weekStart)
    }
}

class ActivityStore: ObservableObject {
    @Published var activities: [Activity] = []
    @Published private(set) var dailyReminderTime: Date
    
    var todayActivities: [Activity] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Group activities by name and get the latest one for each name
        let groupedActivities = Dictionary(grouping: activities.filter { activity in
            calendar.isDate(activity.date, inSameDayAs: today)
        }) { $0.name }
        
        return groupedActivities.values.compactMap { activities in
            activities.max(by: { $0.date < $1.date })
        }.sorted(by: { $0.name < $1.name })
    }
    
    var historicalActivities: [Date: [Activity]] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Group activities by date
        let byDate = Dictionary(grouping: activities.filter { activity in
            !calendar.isDate(activity.date, inSameDayAs: today)
        }) { activity in
            calendar.startOfDay(for: activity.date)
        }
        
        // For each date, group activities by name and get the latest one
        return byDate.mapValues { dateActivities in
            Dictionary(grouping: dateActivities) { $0.name }
                .values
                .compactMap { $0.max(by: { $0.date < $1.date }) }
                .sorted(by: { $0.name < $1.name })
        }
    }
    
    init() {
        // Initialize daily reminder time (default to 8 PM)
        if let savedTime = UserDefaults.standard.object(forKey: "dailyReminderTime") as? Date {
            self.dailyReminderTime = savedTime
        } else {
            self.dailyReminderTime = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()
            UserDefaults.standard.set(self.dailyReminderTime, forKey: "dailyReminderTime")
        }
        
        // Add some sample data
        let calendar = Calendar.current
        let today = Date()
        
        // Create "Reading" activity for today
        let reading = Activity(name: "Reading", timeSpent: 3600, date: today)
        activities.append(reading)
        
        // Add past entries for reading
        for dayOffset in 1...21 {
            if let pastDate = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                let timeSpent = Double.random(in: 1800...7200)
                let pastActivity = Activity(name: "Reading", timeSpent: timeSpent, date: pastDate)
                activities.append(pastActivity)
            }
        }
        
        // Create "Exercise" activity for today
        let exercise = Activity(name: "Exercise", timeSpent: 2700, date: today)
        activities.append(exercise)
        
        // Add past entries for exercise
        for dayOffset in 1...21 {
            if let pastDate = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                let timeSpent = Double.random(in: 2700...5400)
                let pastActivity = Activity(name: "Exercise", timeSpent: timeSpent, date: pastDate)
                activities.append(pastActivity)
            }
        }
    }
    
    func updateReminderTime(_ newTime: Date) {
        dailyReminderTime = newTime
        UserDefaults.standard.set(newTime, forKey: "dailyReminderTime")
    }
    
    func addActivity(_ activity: Activity) {
        activities.append(activity)
        objectWillChange.send()
    }
    
    func updateActivityTime(_ activityId: UUID, timeSpent: TimeInterval) {
        if let index = activities.firstIndex(where: { $0.id == activityId }) {
            activities[index].timeSpent = timeSpent
            objectWillChange.send()
        }
    }

    func getWeeklyStats(for activity: Activity, numberOfWeeks: Int = 4) -> [WeeklyStats] {
        let calendar = Calendar.current
        let today = Date()
        
        // Create an array of week start dates
        var weekStarts: [Date] = []
        for weekIndex in 0..<numberOfWeeks {
            if let weekStart = calendar.date(byAdding: .day,
                                          value: -(weekIndex * 7),
                                          to: calendar.startOfDay(for: today)) {
                weekStarts.insert(weekStart, at: 0)
            }
        }
        
        // Calculate hours for each week
        return weekStarts.map { weekStart in
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
            
            // Filter activities for this week
            let weeklyTime = activities
                .filter { $0.name == activity.name } // Changed to filter by name instead of ID
                .filter { activity in
                    let activityDate = activity.date
                    return activityDate >= weekStart && activityDate < weekEnd
                }
                .reduce(0.0) { sum, activity in
                    sum + activity.timeSpent
                }
            
            return WeeklyStats(
                weekStart: weekStart,
                hours: weeklyTime / 3600.0,
                activity: activity
            )
        }
    }
    
    func deleteActivity(_ id: UUID) {
        // Get the name of the activity to delete
        guard let activityName = activities.first(where: { $0.id == id })?.name else { return }
        
        // Remove all activities with this name
        activities.removeAll { $0.name == activityName }
        
        // Notify observers of the change
        objectWillChange.send()
    }
    
    private func saveActivities() {
        // For future implementation of persistence
        // Currently just a placeholder as we're using in-memory storage
    }
} 