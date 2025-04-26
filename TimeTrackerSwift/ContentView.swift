import SwiftUI
import SwiftData

// Historical Input View
struct HistoricalInputView: View {
    @Binding var isPresented: Bool
    @ObservedObject var activityStore: ActivityStore
    let onSave: (String, Date, TimeInterval) -> Void
    
    @State private var selectedActivity: String = ""
    @State private var selectedDate: Date = Date()
    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    @State private var isNewActivity: Bool = false
    @State private var newActivityName: String = ""
    
    private var existingActivities: [String] {
        Array(Set(activityStore.activities.map { $0.name })).sorted()
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Activity")) {
                    Picker("Select Activity", selection: $isNewActivity) {
                        Text("Existing Activity").tag(false)
                        Text("New Activity").tag(true)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.vertical, 8)
                    
                    if isNewActivity {
                        TextField("New Activity Name", text: $newActivityName)
                    } else {
                        Picker("Activity", selection: $selectedActivity) {
                            ForEach(existingActivities, id: \.self) { activity in
                                Text(activity).tag(activity)
                            }
                        }
                    }
                }
                
                Section(header: Text("Date")) {
                    DatePicker(
                        "Date",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                }
                
                Section(header: Text("Duration")) {
                    HStack {
                        Picker("Hours", selection: $hours) {
                            ForEach(0..<24) { hour in
                                Text("\(hour)h").tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100)
                        
                        Picker("Minutes", selection: $minutes) {
                            ForEach(0..<60) { minute in
                                Text("\(minute)m").tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Add Past Activity")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                },
                trailing: Button("Save") {
                    let activityName = isNewActivity ? newActivityName : selectedActivity
                    let duration = TimeInterval(hours * 3600 + minutes * 60)
                    onSave(activityName, selectedDate, duration)
                    isPresented = false
                }
                .disabled((isNewActivity && newActivityName.isEmpty) || 
                         (!isNewActivity && selectedActivity.isEmpty) ||
                         (hours == 0 && minutes == 0))
            )
        }
        .onAppear {
            if let firstActivity = existingActivities.first {
                selectedActivity = firstActivity
            }
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var activityStore: ActivityStore
    @State private var showingTimeInput = false
    @State private var showingAddActivity = false
    @State private var showingHistoricalInput = false
    @State private var selectedActivity: PersistentActivity?
    @State private var showingReminderSettings = false
    
    init() {
        // Initialize ActivityStore with a nil context, will be updated in onAppear
        _activityStore = StateObject(wrappedValue: ActivityStore())
    }
    
    private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Today's Date Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(dateFormatter.string(from: Date()))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Action Buttons
                    HStack(spacing: 16) {
                        // Add Activity Button
                        Button(action: { showingAddActivity = true }) {
                            VStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 32))
                                Text("Add Activity")
                                    .font(.system(.headline, design: .rounded))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        
                        // Add Historical Data Button
                        Button(action: { showingHistoricalInput = true }) {
                            VStack(spacing: 12) {
                                Image(systemName: "calendar.badge.plus")
                                    .font(.system(size: 32))
                                Text("Add Past Activity")
                                    .font(.system(.headline, design: .rounded))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                            .background(
                                LinearGradient(
                                    colors: [Color.purple.opacity(0.2), Color.indigo.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .indigo],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Activities List
                    LazyVStack(spacing: 16) {
                        ForEach(activityStore.dashboardActivities, id: \.self) { activity in
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
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Susie's Timekeeper")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: HistoryView(activityStore: activityStore)) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingReminderSettings = true }) {
                        Image(systemName: "bell.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                }
            }
            .sheet(isPresented: $showingAddActivity) {
                AddActivitySheet(isPresented: $showingAddActivity) { name in
                    activityStore.addActivity(name: name)
                }
            }
            .sheet(isPresented: $showingHistoricalInput) {
                HistoricalInputView(
                    isPresented: $showingHistoricalInput,
                    activityStore: activityStore,
                    onSave: { name, date, duration in
                        activityStore.addActivity(name: name, date: date, duration: duration)
                    }
                )
            }
            .sheet(isPresented: $showingTimeInput) {
                NavigationView {
                    TimeInputView(
                        activity: selectedActivity?.toActivity() ?? Activity(name: "", timeSpent: 0, date: Date()),
                        isPresented: $showingTimeInput,
                        onSave: { minutes in
                            if let activity = selectedActivity {
                                let timeInSeconds = TimeInterval(minutes * 60)
                                
                                // Check if this is a temporary activity (not yet in database)
                                if activity.timeSpent == 0 && !activityStore.activities.contains(where: { 
                                    $0.name == activity.name && 
                                    Calendar.current.isDate($0.startTime, inSameDayAs: activity.startTime) 
                                }) {
                                    // It's a temporary activity, create a new persistent one
                                    activityStore.addActivity(name: activity.name, duration: timeInSeconds)
                                } else {
                                    // Update existing activity
                                    activity.timeSpent = timeInSeconds
                                    activity.isActive = false
                                    activityStore.saveContext()
                                    activityStore.objectWillChange.send()
                                }
                                selectedActivity = nil
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
        .onAppear {
            activityStore.setModelContext(modelContext)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .modelContainer(for: PersistentActivity.self)
    }
} 