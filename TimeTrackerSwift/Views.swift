import SwiftUI
import Charts
import SwiftData

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
                                if activity.mode == .duration {
                                    Text(activity.toActivity().formattedValue)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("\(activity.count) counts")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let activityToDelete = activities[index]
                                activityStore.deleteActivity(activityToDelete)
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
    
    private var theme: ActivityThemeManager {
        ActivityThemeManager.getTheme(for: activity.name)
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
                    
                    Text(activity.mode == .duration ? 
                         "Total time: \(activity.toActivity().formattedValue)" :
                         "Total count: \(activity.toActivity().formattedValue)")
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            Section(header: Text("Weekly Progress")) {
                Chart(weeklyData, id: \.weekStart) { week in
                    BarMark(
                        x: .value("Week", week.weekLabel),
                        y: .value(activity.mode == .duration ? "Hours" : "Count", 
                                activity.mode == .duration ? week.hours : Double(week.count))
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
                        Text(activity.mode == .duration ? 
                             String(format: "%.1f hours", week.hours) :
                             "\(week.count) counts")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section {
                Button(action: { showingDeleteAlert = true }) {
                    HStack {
                        Spacer()
                        Text("Delete Activity")
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Activity Details")
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Delete Activity"),
                message: Text("Are you sure you want to delete this activity? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    activityStore.deleteActivity(activity)
                    presentationMode.wrappedValue.dismiss()
                },
                secondaryButton: .cancel()
            )
        }
    }
}

// Activity Card View
struct ActivityCard: View {
    let activity: PersistentActivity
    @ObservedObject var activityStore: ActivityStore
    @State private var showingLogTime = false
    
    private var theme: ActivityThemeManager {
        ActivityThemeManager.getTheme(for: activity.name)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            NavigationLink(destination: ActivityDetailView(
                activity: activity,
                weeklyData: activityStore.getWeeklyStats(for: activity),
                activityStore: activityStore
            )) {
                HStack {
                    Image(systemName: theme.icon)
                        .font(.title2)
                        .foregroundColor(theme.color)
                    Text(activity.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
            
            Spacer()
            
            HStack {
                Button(action: { showingLogTime = true }) {
                    HStack {
                        Image(systemName: activity.mode == .duration ? "clock.fill" : "plus.circle.fill")
                            .foregroundColor(theme.color)
                        Text(activity.mode == .duration ? "Log Time" : "Add Count")
                            .foregroundColor(theme.color)
                    }
                }
                
                Spacer()
                
                HStack {
                    Image(systemName: activity.mode == .duration ? "clock" : "number.circle")
                        .foregroundColor(.secondary)
                    Text(activity.toActivity().formattedValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 120)
        .background(theme.color.opacity(0.1))
        .cornerRadius(12)
        .sheet(isPresented: $showingLogTime) {
            LogTimeView(activityStore: activityStore, activity: activity)
        }
    }
}

// Add Activity Sheet
struct AddActivitySheet: View {
    @Binding var isPresented: Bool
    let onAdd: (String, ActivityMode) -> Void
    @State private var activityName = ""
    @State private var mode: ActivityMode = .duration
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("New Activity")) {
                    TextField("Activity Name", text: $activityName)
                    
                    Picker("Mode", selection: $mode) {
                        Text("Duration").tag(ActivityMode.duration)
                        Text("Count").tag(ActivityMode.count)
                    }
                }
            }
            .navigationTitle("Add Activity")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                },
                trailing: Button("Add") {
                    if !activityName.isEmpty {
                        onAdd(activityName, mode)
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