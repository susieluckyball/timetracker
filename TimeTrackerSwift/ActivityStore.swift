import Foundation
import SwiftUI
import SwiftData

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

@MainActor
class ActivityStore: ObservableObject {
    private var modelContext: ModelContext?
    @Published var activities: [PersistentActivity] = []
    @Published var dailyReminderTime: Date
    
    var dashboardActivities: [PersistentActivity] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Get all unique activity names
        let uniqueNames = Set(activities.map { $0.name })
        
        // For each unique name, get or create today's activity
        let todayActivities = uniqueNames.compactMap { name -> PersistentActivity? in
            // Try to find an existing activity for today
            if let existing = activities.first(where: { activity in
                activity.name == name && calendar.isDate(activity.startTime, inSameDayAs: today)
            }) {
                return existing
            }
            
            // Create a temporary activity for display only (not inserted into context)
            let tempActivity = PersistentActivity(
                name: name,
                startTime: today,
                isActive: false,
                timeSpent: 0
            )
            
            return tempActivity
        }
        
        return todayActivities.sorted(by: { $0.name < $1.name })
    }
    
    var historicalActivities: [Date: [PersistentActivity]] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Group activities by date, excluding activities with 0 duration
        let byDate = Dictionary(grouping: activities.filter { activity in
            !calendar.isDate(activity.startTime, inSameDayAs: today) && activity.duration > 0
        }) { activity in
            calendar.startOfDay(for: activity.startTime)
        }
        
        return byDate
    }
    
    init() {
        // Initialize daily reminder time (default to 8 PM)
        if let savedTime = UserDefaults.standard.object(forKey: "dailyReminderTime") as? Date {
            self.dailyReminderTime = savedTime
        } else {
            self.dailyReminderTime = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()
            UserDefaults.standard.set(self.dailyReminderTime, forKey: "dailyReminderTime")
        }
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadActivities()
    }
    
    private func loadActivities() {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<PersistentActivity>(
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )
            activities = try context.fetch(descriptor)
            
            // Create today's activities if needed
            _ = dashboardActivities
        } catch {
            print("Failed to load activities: \(error)")
            activities = []
        }
    }
    
    func updateReminderTime(_ newTime: Date) {
        dailyReminderTime = newTime
        UserDefaults.standard.set(newTime, forKey: "dailyReminderTime")
    }
    
    func addActivity(name: String, date: Date = Date(), duration: TimeInterval = 0) {
        guard let context = modelContext else { return }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        // Check if activity already exists for this day
        if let existingActivity = activities.first(where: { activity in
            activity.name == name && calendar.isDate(activity.startTime, inSameDayAs: startOfDay)
        }) {
            // Update existing activity
            existingActivity.timeSpent = duration
            existingActivity.isActive = false
        } else {
            // Create new activity
            let activity = PersistentActivity(
                name: name,
                startTime: date,
                isActive: false,
                timeSpent: duration
            )
            context.insert(activity)
            activities.append(activity)
        }
        
        saveContext()
        objectWillChange.send()
    }
    
    func startTracking(_ activity: PersistentActivity) {
        activity.isActive = true
        activity.startTime = Date()
        saveContext()
        objectWillChange.send()
    }
    
    func stopTracking(_ activity: PersistentActivity) {
        // Calculate duration since activity started tracking
        let duration = Date().timeIntervalSince(activity.startTime)
        
        // Update activity
        activity.isActive = false
        activity.timeSpent = duration
        
        saveContext()
        objectWillChange.send()
    }
    
    func deleteActivity(_ activity: PersistentActivity) {
        guard let context = modelContext else { return }
        
        context.delete(activity)
        if let index = activities.firstIndex(where: { $0.startTime == activity.startTime }) {
            activities.remove(at: index)
        }
        saveContext()
    }
    
func getWeeklyStats(for activity: PersistentActivity, numberOfWeeks: Int = 4) -> [WeeklyStats] {
    var calendar = Calendar.current
    calendar.firstWeekday = 1  // 1 = Sunday
    let today = Date()
    
    var weekStarts: [Date] = []
    for weekIndex in 0..<numberOfWeeks {
        // Find the most recent Sunday
        let todayWeekday = calendar.component(.weekday, from: today)
        let daysToSubtract = todayWeekday - 1
        
        // Calculate the start of the current week (Sunday)
        if let currentWeekStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: calendar.startOfDay(for: today)),
           let weekStart = calendar.date(byAdding: .day, value: -(weekIndex * 7), to: currentWeekStart) {
            weekStarts.insert(weekStart, at: 0)
        }
    }
    
    return weekStarts.map { weekStart in
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
        
        let weeklyTime = activities
            .filter { $0.name == activity.name }
            .filter { activity in
                let activityDate = activity.startTime
                return activityDate >= weekStart && activityDate < weekEnd
            }
            .reduce(0.0) { sum, activity in
                sum + activity.timeSpent
            }
        
        return WeeklyStats(
            weekStart: weekStart,
            hours: weeklyTime / 3600.0,
            activity: activity.toActivity()
        )
    }
}
    func saveContext() {
        guard let context = modelContext else { return }
        
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
} 