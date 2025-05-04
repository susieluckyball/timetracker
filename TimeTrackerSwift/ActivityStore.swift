import Foundation
import SwiftUI
import SwiftData

struct WeeklyStats {
    let weekStart: Date
    let hours: Double
    let count: Int
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
    @Published var lastHistoricalInputDate: Date
    @Published var currentDate = Date() {
        didSet {
            // Check if the day has changed
            let calendar = Calendar.current
            if !calendar.isDate(currentDate, inSameDayAs: oldValue) {
                // Day has changed, ensure activities exist for the new day
                ensureAllActivitiesExistForToday()
                // Notify observers of the change
                objectWillChange.send()
            }
        }
    }
    private var dateUpdateTimer: Timer?
    
    // Debug property to track activity additions
    private var isDebugMode = true
    
    // Debug function to simulate date changes
    func simulateDateChange(daysToAdd: Int) {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .day, value: daysToAdd, to: currentDate) {
            print("Debug: Simulating date change from \(currentDate) to \(newDate)")
            currentDate = newDate
        }
    }
    
    var dashboardActivities: [PersistentActivity] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: currentDate)
        
        // Get all unique activity names
        let uniqueNames = Set(activities.map { $0.name })
        
        // For each unique name, get today's activity
        let todayActivities = uniqueNames.compactMap { name -> PersistentActivity? in
            // Try to find an existing activity for today
            activities.first(where: { activity in
                activity.name == name && calendar.isDate(activity.startTime, inSameDayAs: today)
            })
        }
        
        return todayActivities.sorted(by: { $0.name < $1.name })
    }
    
    var historicalActivities: [Date: [PersistentActivity]] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: currentDate)
        
        // Group activities by date, excluding activities with 0 duration/count
        let byDate = Dictionary(grouping: activities.filter { activity in
            !calendar.isDate(activity.startTime, inSameDayAs: today) && 
            (activity.mode == .duration ? activity.timeSpent > 0 : activity.count > 0)
        }) { activity in
            calendar.startOfDay(for: activity.startTime)
        }
        
        return byDate
    }
    
    init() {
        self.dailyReminderTime = UserDefaults.standard.object(forKey: "dailyReminderTime") as? Date ?? Calendar.current.date(from: DateComponents(hour: 20, minute: 0))!
        self.lastHistoricalInputDate = UserDefaults.standard.object(forKey: "lastHistoricalInputDate") as? Date ?? Date()
        
        // Set up a timer to update the current date every minute
        dateUpdateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.currentDate = Date()
            }
        }
    }
    
    deinit {
        dateUpdateTimer?.invalidate()
        dateUpdateTimer = nil
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
            
            if isDebugMode {
                print("Loaded \(activities.count) activities")
                for activity in activities {
                    print("  - \(activity.name) on \(activity.startTime), mode: \(activity.mode), timeSpent: \(activity.timeSpent), count: \(activity.count)")
                }
            }
            
            // Ensure all activities exist for today
            ensureAllActivitiesExistForToday()
        } catch {
            print("Failed to load activities: \(error)")
            activities = []
        }
    }
    
    private func ensureAllActivitiesExistForToday() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: currentDate)
        
        // Get all unique activity names
        let uniqueNames = Set(activities.map { $0.name })
        
        // For each unique name, ensure there's an activity for today
        for name in uniqueNames {
            // Find the most recent activity with this name to get its mode
            if let lastActivity = activities
                .filter({ $0.name == name })
                .sorted(by: { $0.startTime > $1.startTime })
                .first {
                
                // Check if activity already exists for today
                if !activities.contains(where: { activity in
                    activity.name == name && calendar.isDate(activity.startTime, inSameDayAs: today)
                }) {
                    // Create a new activity for today
                    let newActivity = PersistentActivity(
                        name: name,
                        mode: lastActivity.mode,
                        startTime: today,
                        timeSpent: 0,
                        count: 0
                    )
                    
                    if let context = modelContext {
                        context.insert(newActivity)
                        activities.append(newActivity)
                        if isDebugMode {
                            print("Created new activity for today: \(name)")
                        }
                    }
                }
            }
        }
        
        // Save any new activities
        saveContext()
    }
    
    func updateReminderTime(_ newTime: Date) {
        dailyReminderTime = newTime
        UserDefaults.standard.set(newTime, forKey: "dailyReminderTime")
    }
    
    func updateLastHistoricalInputDate(_ date: Date) {
        lastHistoricalInputDate = date
        UserDefaults.standard.set(date, forKey: "lastHistoricalInputDate")
    }
    
    func addActivity(name: String, mode: ActivityMode, date: Date = Date(), duration: TimeInterval? = 0, count: Int? = 0) {
        guard let context = modelContext else { return }
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Don't allow empty activity names
        if trimmedName.isEmpty {
            return
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        if isDebugMode {
            print("Adding activity: \(trimmedName) for date \(startOfDay), mode: \(mode), duration: \(duration ?? 0), count: \(count ?? 0)")
        }
        
        // First, fetch the latest activities to ensure we have the most current data
        loadActivities()
        
        // Check if activity already exists for this day - use exact matching for name
        let existingActivityIndex = activities.firstIndex(where: { activity in
            let activityName = activity.name.trimmingCharacters(in: .whitespacesAndNewlines)
            return activityName == trimmedName && calendar.isDate(activity.startTime, inSameDayAs: startOfDay)
        })
        
        if let index = existingActivityIndex {
            // Update existing activity
            let existingActivity = activities[index]
            
            if isDebugMode {
                print("Found existing activity: \(existingActivity.name) on \(existingActivity.startTime)")
            }
            
            existingActivity.mode = mode
            if mode == .duration {
                existingActivity.timeSpent = duration ?? 0
                existingActivity.count = 0
            } else {
                existingActivity.timeSpent = 0
                existingActivity.count = count ?? 0
            }
        } else {
            // Create new activity with exact startOfDay time for consistent comparison
            let activity = PersistentActivity(
                name: trimmedName,
                mode: mode,
                startTime: startOfDay,
                timeSpent: mode == .duration ? (duration ?? 0) : 0,
                count: mode == .count ? (count ?? 0) : 0
            )
            
            if isDebugMode {
                print("Creating new activity: \(activity.name) on \(activity.startTime)")
            }
            
            context.insert(activity)
            activities.append(activity)
        }
        
        // Make sure to save after each operation
        saveContext()
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    func incrementCounter(for activity: PersistentActivity) {
        guard modelContext != nil else { return }
        
        if isDebugMode {
            print("Incrementing counter for activity: \(activity.name)")
        }
        
        activity.count += 1
        saveContext()
        objectWillChange.send()
    }
    
    func resetCounter(for activity: PersistentActivity) {
        guard modelContext != nil else { return }
        
        if isDebugMode {
            print("Resetting counter for activity: \(activity.name)")
        }
        
        activity.count = 0
        saveContext()
        objectWillChange.send()
    }
    
    func deleteActivity(_ activity: PersistentActivity) {
        guard let context = modelContext else { return }
        
        if isDebugMode {
            print("Deleting all activities with name: \(activity.name)")
        }
        
        // Find all activities with the same name
        let activitiesToDelete = activities.filter { $0.name == activity.name }
        
        // Delete each activity from the context
        for activityToDelete in activitiesToDelete {
            context.delete(activityToDelete)
        }
        
        // Remove all matching activities from our array
        activities.removeAll { $0.name == activity.name }
        
        saveContext()
        loadActivities()  // Reload activities after deletion
        objectWillChange.send()  // Notify UI of changes
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
            
            let weeklyActivities = activities
                .filter { $0.name == activity.name }
                .filter { activity in
                    let activityDate = activity.startTime
                    return activityDate >= weekStart && activityDate < weekEnd
                }
            
            let weeklyTime = weeklyActivities.reduce(0.0) { sum, activity in
                sum + activity.timeSpent
            }
            
            let weeklyCount = weeklyActivities.reduce(0) { sum, activity in
                sum + activity.count
            }
            
            return WeeklyStats(
                weekStart: weekStart,
                hours: weeklyTime / 3600.0,
                count: weeklyCount,
                activity: activity.toActivity()
            )
        }
    }
    
    func saveContext() {
        guard let context = modelContext else { return }
        
        do {
            try context.save()
            if isDebugMode {
                print("Context saved successfully")
            }
        } catch {
            print("Failed to save context: \(error)")
        }
    }
    
    func ensureTodayActivityExists(for name: String, mode: ActivityMode) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Check if activity already exists for today
        if !activities.contains(where: { activity in
            activity.name == name && calendar.isDate(activity.startTime, inSameDayAs: today)
        }) {
            // Create a new activity for today
            let newActivity = PersistentActivity(
                name: name,
                mode: mode,
                startTime: today,
                timeSpent: 0,
                count: 0
            )
            
            if let context = modelContext {
                context.insert(newActivity)
                activities.append(newActivity)
                saveContext()
            }
        }
    }
    
    // Generate CSV data from activities
    func generateCSVData() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // CSV Header
        var csvString = "Date,Activity Name,Mode,Duration (hours),Count\n"
        
        // Sort activities by date
        let sortedActivities = activities.sorted { $0.startTime < $1.startTime }
        
        // Add each activity as a row
        for activity in sortedActivities {
            let date = dateFormatter.string(from: activity.startTime)
            let duration = activity.mode == .duration ? String(format: "%.2f", activity.timeSpent / 3600.0) : "0"
            let count = activity.mode == .count ? String(activity.count) : "0"
            
            // Escape any commas in the activity name
            let escapedName = activity.name.replacingOccurrences(of: ",", with: ";")
            
            csvString += "\(date),\(escapedName),\(activity.mode),\(duration),\(count)\n"
        }
        
        return csvString
    }
    
    // Export activities to CSV file
    func exportToCSV() -> URL? {
        let csvString = generateCSVData()
        
        // Create a temporary file URL
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let fileName = "activities_export_\(Date().timeIntervalSince1970).csv"
        let fileURL = temporaryDirectoryURL.appendingPathComponent(fileName)
        
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error writing CSV file: \(error)")
            return nil
        }
    }
}
