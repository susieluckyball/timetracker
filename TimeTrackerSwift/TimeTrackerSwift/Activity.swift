import Foundation
import UserNotifications

struct Activity: Identifiable, Codable {
    var id = UUID()
    var name: String
    var timeSpent: TimeInterval  // in minutes
    var date: Date
    
    var formattedTime: String {
        let hours = Int(timeSpent) / 60
        let minutes = Int(timeSpent) % 60
        return String(format: "%dh %dm", hours, minutes)
    }
}

class ActivityStore: ObservableObject {
    @Published var activities: [Activity] = []
    @Published var dailyReminderTime: Date = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
    
    private let saveKey = "SavedActivities"
    private let reminderTimeKey = "DailyReminderTime"
    
    init() {
        loadActivities()
        loadReminderTime()
        scheduleDailyReminder()
    }
    
    func addActivity(_ activity: Activity) {
        activities.append(activity)
        saveActivities()
    }
    
    func updateReminderTime(_ time: Date) {
        dailyReminderTime = time
        UserDefaults.standard.set(time, forKey: reminderTimeKey)
        scheduleDailyReminder()
    }
    
    func getWeeklyStats() -> [Activity] {
        let calendar = Calendar.current
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        
        return activities.filter { $0.date >= oneWeekAgo }
    }
    
    private func scheduleDailyReminder() {
        let center = UNUserNotificationCenter.current()
        
        // Remove existing notifications
        center.removeAllPendingNotificationRequests()
        
        // Request permission if needed
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                let content = UNMutableNotificationContent()
                content.title = "Time Tracker Reminder"
                content.body = "Don't forget to log your activities for today!"
                content.sound = .default
                
                // Create trigger for daily reminder
                let calendar = Calendar.current
                var components = calendar.dateComponents([.hour, .minute], from: self.dailyReminderTime)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                
                // Create request
                let request = UNNotificationRequest(identifier: "DailyReminder", content: content, trigger: trigger)
                
                // Add request
                center.add(request) { error in
                    if let error = error {
                        print("Error scheduling notification: \(error)")
                    }
                }
            }
        }
    }
    
    private func saveActivities() {
        if let encoded = try? JSONEncoder().encode(activities) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadActivities() {
        if let data = UserDefaults.standard.data(forKey: saveKey) {
            if let decoded = try? JSONDecoder().decode([Activity].self, from: data) {
                activities = decoded
                return
            }
        }
        activities = []
    }
    
    private func loadReminderTime() {
        if let savedTime = UserDefaults.standard.object(forKey: reminderTimeKey) as? Date {
            dailyReminderTime = savedTime
        }
    }
} 