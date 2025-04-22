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
    
    var todayActivities: [PersistentActivity] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return activities.filter { activity in
            calendar.isDate(activity.startTime, inSameDayAs: today)
        }.sorted(by: { $0.name < $1.name })
    }
    
    var historicalActivities: [Date: [PersistentActivity]] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Group activities by date
        let byDate = Dictionary(grouping: activities.filter { activity in
            !calendar.isDate(activity.startTime, inSameDayAs: today)
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
            let descriptor = FetchDescriptor<PersistentActivity>(sortBy: [SortDescriptor(\.startTime, order: .reverse)])
            activities = try context.fetch(descriptor)
        } catch {
            print("Failed to load activities: \(error)")
            activities = []
        }
    }
    
    func updateReminderTime(_ newTime: Date) {
        dailyReminderTime = newTime
        UserDefaults.standard.set(newTime, forKey: "dailyReminderTime")
    }
    
    func addActivity(name: String) {
        guard let context = modelContext else { return }
        
        let activity = PersistentActivity(name: name)
        context.insert(activity)
        activities.append(activity)
        saveContext()
    }
    
    func startTracking(_ activity: PersistentActivity) {
        activity.isActive = true
        activity.startTime = Date()
        activity.endTime = nil
        saveContext()
        objectWillChange.send()
    }
    
    func stopTracking(_ activity: PersistentActivity) {
        guard let endTime = activity.endTime else { return }
        
        // Update the existing activity's duration
        let duration = endTime.timeIntervalSince(activity.startTime)
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
        let calendar = Calendar.current
        let today = Date()
        
        var weekStarts: [Date] = []
        for weekIndex in 0..<numberOfWeeks {
            if let weekStart = calendar.date(byAdding: .day,
                                          value: -(weekIndex * 7),
                                          to: calendar.startOfDay(for: today)) {
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
                    sum + (activity.timeSpent ?? 0)
                }
            
            return WeeklyStats(
                weekStart: weekStart,
                hours: weeklyTime / 3600.0,
                activity: activity.toActivity()
            )
        }
    }
    
    private func saveContext() {
        guard let context = modelContext else { return }
        
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
} 