import SwiftUI
import Charts

struct ActivityTheme {
    let color: Color
    let icon: String
    
    static let themes: [String: ActivityTheme] = [
        "Reading": ActivityTheme(color: .blue, icon: "book.fill"),
        "Exercise": ActivityTheme(color: .green, icon: "figure.run"),
        "Work": ActivityTheme(color: .orange, icon: "briefcase.fill"),
        "Study": ActivityTheme(color: .purple, icon: "graduationcap.fill"),
        "Gaming": ActivityTheme(color: .red, icon: "gamecontroller.fill"),
        "Meditation": ActivityTheme(color: .teal, icon: "leaf.fill"),
        "Music": ActivityTheme(color: .pink, icon: "music.note"),
        "Art": ActivityTheme(color: .indigo, icon: "paintbrush.fill"),
        "Cooking": ActivityTheme(color: .yellow, icon: "fork.knife"),
        "Sleep": ActivityTheme(color: .gray, icon: "moon.fill"),
        "Podcast": ActivityTheme(color: .purple, icon: "headphones"),
        "Gym": ActivityTheme(color: .red, icon: "dumbbell.fill")
    ]
    
    static func getTheme(for activityName: String) -> ActivityTheme {
        // Default theme for activities not in the predefined list
        let defaultTheme = ActivityTheme(color: .blue, icon: "star.fill")
        
        // Check if the activity name contains any of our known keywords
        for (keyword, theme) in themes {
            if activityName.lowercased().contains(keyword.lowercased()) {
                return theme
            }
        }
        
        return defaultTheme
    }
}

// History View
struct HistoryView: View {
    @ObservedObject var activityStore: ActivityStore
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()
    
    var sortedDates: [Date] {
        activityStore.historicalActivities.keys.sorted(by: >)
    }
    
    var body: some View {
        List {
            ForEach(sortedDates, id: \.self) { date in
                Section(header: Text(dateFormatter.string(from: date))) {
                    if let activities = activityStore.historicalActivities[date] {
                        ForEach(activities) { activity in
                            HStack {
                                Text(activity.name)
                                Spacer()
                                Text(activity.formattedTime)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("History")
    }
}

// Activity Detail View
struct ActivityDetailView: View {
    let activity: Activity
    let weeklyData: [WeeklyStats]
    @Environment(\.presentationMode) var presentationMode
    let activityStore: ActivityStore
    @State private var showingDeleteAlert = false
    
    private var theme: ActivityTheme {
        ActivityTheme.getTheme(for: activity.name)
    }
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: theme.icon)
                            .font(.title)
                            .foregroundColor(theme.color)
                        Text(activity.name)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Text("Total time: \(activity.formattedTime)")
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            Section(header: Text("Weekly Progress")) {
                Chart(weeklyData, id: \.weekStart) { week in
                    BarMark(
                        x: .value("Week", week.weekLabel),
                        y: .value("Hours", week.hours)
                    )
                    .foregroundStyle(theme.color.gradient)
                }
                .frame(height: 200)
                .padding(.vertical)
            }
            
            Section(header: Text("Weekly Breakdown")) {
                ForEach(weeklyData.reversed(), id: \.weekStart) { week in
                    HStack {
                        Text(week.weekLabel)
                        Spacer()
                        Text(String(format: "%.1f hours", week.hours))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section {
                Button(role: .destructive, action: {
                    showingDeleteAlert = true
                }) {
                    HStack {
                        Spacer()
                        Text("Delete Activity")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Activity Details")
        .alert("Delete Activity", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Everything", role: .destructive) {
                activityStore.deleteActivity(activity.id)
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("This will delete '\(activity.name)' and all of its history. This action cannot be undone.")
        }
    }
}

// Main Content View
struct ContentView: View {
    @StateObject private var activityStore = ActivityStore()
    @State private var showingTimeInput = false
    @State private var showingAddActivity = false
    @State private var selectedActivity: Activity?
    @State private var showingReminderSettings = false
    
    private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Today's Date Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dateFormatter.string(from: Date()))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("Susie: Track your time!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Activities Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        // Add Activity Button
                        Button(action: { showingAddActivity = true }) {
                            VStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 30))
                                Text("Add Activity")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)  // Slightly reduced height for single column
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Today's Activities
                        ForEach(activityStore.todayActivities) { activity in
                            ActivityCard(activity: activity, onTap: {
                                selectedActivity = activity
                                showingTimeInput = true
                            }, activityStore: activityStore)
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Time Tracker")
            .navigationBarItems(
                leading: NavigationLink(destination: HistoryView(activityStore: activityStore)) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.title2)
                },
                trailing: Button(action: { showingReminderSettings = true }) {
                    Image(systemName: "bell.circle.fill")
                        .font(.title2)
                }
            )
            .sheet(isPresented: $showingAddActivity) {
                AddActivitySheet(isPresented: $showingAddActivity) { name in
                    let activity = Activity(name: name, timeSpent: 0, date: Date())
                    activityStore.addActivity(activity)
                }
            }
            .sheet(isPresented: $showingTimeInput) {
                NavigationView {
                    TimeInputView(
                        activity: selectedActivity ?? Activity(name: "", timeSpent: 0, date: Date()),
                        isPresented: $showingTimeInput,
                        onSave: { minutes in
                            if let activity = selectedActivity {
                                let timeInSeconds = TimeInterval(minutes * 60)
                                activityStore.updateActivityTime(activity.id, timeSpent: timeInSeconds)
                            }
                        }
                    )
                }
            }
            .sheet(isPresented: $showingReminderSettings) {
                ReminderSettingsView(
                    reminderTime: activityStore.dailyReminderTime,
                    onSave: { newTime in
                        activityStore.updateReminderTime(newTime)
                        showingReminderSettings = false
                    }
                )
            }
        }
    }
}

// Activity Card View
struct ActivityCard: View {
    let activity: Activity
    let onTap: () -> Void
    @ObservedObject var activityStore: ActivityStore
    
    private var theme: ActivityTheme {
        ActivityTheme.getTheme(for: activity.name)
    }
    
    var body: some View {
        NavigationLink(destination: ActivityDetailView(
            activity: activity,
            weeklyData: activityStore.getWeeklyStats(for: activity),
            activityStore: activityStore
        )) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: theme.icon)
                        .font(.title2)
                        .foregroundColor(theme.color)
                    Text(activity.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                HStack {
                    Button(action: {
                        onTap()
                    }) {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                    }
                    Text(activity.formattedTime)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 120)
            .background(theme.color.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Add Activity Sheet
struct AddActivitySheet: View {
    @Binding var isPresented: Bool
    let onAdd: (String) -> Void
    @State private var activityName = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("New Activity")) {
                    TextField("Activity Name", text: $activityName)
                }
            }
            .navigationTitle("Add Activity")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                },
                trailing: Button("Add") {
                    if !activityName.isEmpty {
                        onAdd(activityName)
                        isPresented = false
                    }
                }
                .disabled(activityName.isEmpty)
            )
        }
    }
}

// Time Input View
struct TimeInputView: View {
    let activity: Activity
    @Binding var isPresented: Bool
    let onSave: (Int) -> Void
    @State private var hours: String = ""
    @State private var minutes: String = ""
    @FocusState private var focusedField: Field?
    
    enum Field {
        case hours, minutes
    }
    
    var body: some View {
        Form {
            Section(header: Text("Log time for \(activity.name)")) {
                HStack {
                    TextField("Hours", text: $hours)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .hours)
                        .onChange(of: hours) { newValue in
                            if let number = Int(newValue), number > 23 {
                                hours = "23"
                            }
                            if newValue.count > 2 {
                                hours = String(newValue.prefix(2))
                            }
                        }
                    Text("hours")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    TextField("Minutes", text: $minutes)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .minutes)
                        .onChange(of: minutes) { newValue in
                            if let number = Int(newValue), number > 59 {
                                minutes = "59"
                            }
                            if newValue.count > 2 {
                                minutes = String(newValue.prefix(2))
                            }
                        }
                    Text("minutes")
                        .foregroundColor(.secondary)
                }
            }
            
            Section {
                Button(action: saveTime) {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                }
                .listRowBackground(Color.blue)
            }
        }
        .navigationTitle("Log Time")
        .navigationBarItems(
            leading: Button("Cancel") {
                isPresented = false
            },
            trailing: Button("Save", action: saveTime)
        )
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                HStack {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
        }
    }
    
    private func saveTime() {
        let hoursValue = Int(hours) ?? 0
        let minutesValue = Int(minutes) ?? 0
        let totalMinutes = hoursValue * 60 + minutesValue
        
        if totalMinutes > 0 {
            onSave(totalMinutes)
            isPresented = false
        }
    }
}

// Reminder Settings View
struct ReminderSettingsView: View {
    let reminderTime: Date
    let onSave: (Date) -> Void
    @State private var selectedTime: Date
    @Environment(\.presentationMode) var presentationMode
    
    init(reminderTime: Date, onSave: @escaping (Date) -> Void) {
        self.reminderTime = reminderTime
        self.onSave = onSave
        _selectedTime = State(initialValue: reminderTime)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Daily Reminder Time")) {
                    DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                }
            }
            .navigationTitle("Reminder Settings")
            .navigationBarItems(
                trailing: Button("Save") {
                    onSave(selectedTime)
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// Preview Providers
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HistoryView(activityStore: ActivityStore())
        }
    }
}

struct ActivityDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleActivity = Activity(name: "Sample Activity", timeSpent: 3600, date: Date())
        let calendar = Calendar.current
        let store = ActivityStore()
        
        return NavigationView {
            ActivityDetailView(
                activity: sampleActivity,
                weeklyData: [
                    WeeklyStats(weekStart: calendar.date(byAdding: .day, value: -21, to: Date())!, hours: 2.5, activity: sampleActivity),
                    WeeklyStats(weekStart: calendar.date(byAdding: .day, value: -14, to: Date())!, hours: 3.0, activity: sampleActivity),
                    WeeklyStats(weekStart: calendar.date(byAdding: .day, value: -7, to: Date())!, hours: 1.5, activity: sampleActivity),
                    WeeklyStats(weekStart: Date(), hours: 4.0, activity: sampleActivity)
                ],
                activityStore: store
            )
        }
    }
} 