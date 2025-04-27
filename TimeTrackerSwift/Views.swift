import SwiftUI
import Charts
import SwiftData

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
        let dates = activityStore.historicalActivities.keys
        return Array(dates).sorted(by: >)
    }
    
    var body: some View {
        List {
            ForEach(sortedDates, id: \.self) { date in
                Section(header: Text(dateFormatter.string(from: date))) {
                    if let activities = activityStore.historicalActivities[date] {
                        ForEach(activities, id: \.id) { activity in
                            HStack {
                                Text(activity.name)
                                Spacer()
                                Text(activity.toActivity().formattedTime)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                activityStore.deleteActivity(activities[index])
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
    let activity: PersistentActivity
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
                    
                    Text("Total time: \(activity.toActivity().formattedTime)")
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
                activityStore.deleteActivity(activity)
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("This will delete '\(activity.name)' and all of its history. This action cannot be undone.")
        }
    }
}

// Activity Card View
struct ActivityCard: View {
    let activity: PersistentActivity
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
                    Button(action: onTap) {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                    }
                    Text(activity.toActivity().formattedTime)
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
                        .onChange(of: hours) { oldValue, newValue in
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
                        .onChange(of: minutes) { oldValue, newValue in
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
        } else {
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
#Preview {
    let preview = try! ModelContainer(for: PersistentActivity.self)
    let store = ActivityStore()
    store.setModelContext(preview.mainContext)
    
    return NavigationView {
        HistoryView(activityStore: store)
    }
    .modelContainer(preview)
} 