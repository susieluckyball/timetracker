import SwiftUI
import SwiftData

struct HistoricalInputView: View {
    @Binding var isPresented: Bool
    @ObservedObject var activityStore: ActivityStore
    let onSave: (String, Date, TimeInterval, ActivityMode, Int) -> Void
    
    @State private var selectedActivity: String = ""
    @State private var selectedDate: Date
    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    @State private var count: Int = 0
    @State private var isNewActivity: Bool = false
    @State private var newActivityName: String = ""
    @State private var mode: ActivityMode = .duration
    
    init(isPresented: Binding<Bool>, activityStore: ActivityStore, onSave: @escaping (String, Date, TimeInterval, ActivityMode, Int) -> Void) {
        self._isPresented = isPresented
        self.activityStore = activityStore
        self.onSave = onSave
        
        // Initialize date with the last historical input date
        self._selectedDate = State(initialValue: activityStore.lastHistoricalInputDate)
    }
    
    private var existingActivities: [String] {
        // Get unique activity names
        Array(Set(activityStore.activities.map { $0.name })).sorted()
    }
    
    private func updateModeForSelectedActivity() {
        if !isNewActivity && !selectedActivity.isEmpty {
            // Find the most recent activity with this name to get its mode
            if let activity = activityStore.activities
                .filter({ $0.name == selectedActivity })
                .sorted(by: { $0.startTime > $1.startTime })
                .first {
                mode = activity.mode
                print("Updated mode to: \(mode) for activity: \(selectedActivity)")
            }
        }
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
                            .onChange(of: newActivityName) { oldValue, newValue in
                                newActivityName = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                            }
                        
                        Picker("Mode", selection: $mode) {
                            Text("Duration").tag(ActivityMode.duration)
                            Text("Count").tag(ActivityMode.count)
                        }
                    } else if !existingActivities.isEmpty {
                        Picker("Activity", selection: $selectedActivity) {
                            ForEach(existingActivities, id: \.self) { activity in
                                Text(activity).tag(activity)
                            }
                        }
                        .onChange(of: selectedActivity) { oldValue, newValue in
                            updateModeForSelectedActivity()
                        }
                        
                        if !selectedActivity.isEmpty {
                            Text("Mode: \(mode == .duration ? "Duration" : "Count")")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("No existing activities")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Date")) {
                    DatePicker(
                        "Date",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                }
                
                if mode == .duration {
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
                                ForEach(0..<12) { minute in
                                    Text("\(minute * 5)m").tag(minute * 5)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100)
                        }
                        .padding(.vertical)
                    }
                } else {
                    Section(header: Text("Count")) {
                        HStack {
                            Picker("Count", selection: $count) {
                                ForEach(0..<100) { count in
                                    Text("\(count)").tag(count)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100)
                        }
                        .padding(.vertical)
                    }
                }
                
                #if DEBUG
                // Debug section to see current state
                Section(header: Text("Debug Info")) {
                    Text("Using new activity: \(isNewActivity ? "Yes" : "No")")
                    if isNewActivity {
                        Text("New activity name: \"\(newActivityName)\"")
                    } else {
                        Text("Selected activity: \"\(selectedActivity)\"")
                    }
                    Text("Date: \(selectedDate, format: .dateTime)")
                    Text("Mode: \(mode == .duration ? "Duration" : "Count")")
                    if mode == .duration {
                        Text("Duration: \(hours)h \(minutes)m")
                    } else {
                        Text("Count: \(count)")
                    }
                }
                #endif
            }
            .navigationTitle("Add Past Activity")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                },
                trailing: Button("Save") {
                    let activityName: String
                    if isNewActivity {
                        activityName = newActivityName.trimmingCharacters(in: .whitespacesAndNewlines)
                    } else {
                        activityName = selectedActivity
                    }
                    
                    let calendar = Calendar.current
                    let startOfDay = calendar.startOfDay(for: selectedDate)
                    let duration = TimeInterval(hours * 3600 + minutes * 60)
                    
                    print("Saving activity: \(activityName), mode: \(mode), count: \(count), duration: \(duration)")
                    
                    // Only save if we have valid data
                    if !activityName.isEmpty && (mode == .count ? count > 0 : duration > 0) {
                        onSave(activityName, startOfDay, duration, mode, count)
                        
                        // Update the last historical input date
                        activityStore.updateLastHistoricalInputDate(startOfDay)
                        
                        // Reset the form
                        newActivityName = ""
                        hours = 0
                        minutes = 0
                        count = 0
                        
                        isPresented = false
                    }
                }
                .disabled((isNewActivity && newActivityName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) || 
                         (!isNewActivity && (selectedActivity.isEmpty || existingActivities.isEmpty)) ||
                         (mode == .duration ? (hours == 0 && minutes == 0) : count == 0))
            )
        }
        .onAppear {
            // Reset state when view appears
            if let firstActivity = existingActivities.first, !isNewActivity {
                selectedActivity = firstActivity
                updateModeForSelectedActivity()
            }
        }
    }
}

// Extension to trim whitespace and newlines from strings
extension String {
    func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
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
    @State private var showingExportSheet = false
    @State private var exportURL: URL?
    
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
                        Text(dateFormatter.string(from: activityStore.currentDate))
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
                    
                    // Activity Cards
                    LazyVStack(spacing: 16) {
                        ForEach(activityStore.dashboardActivities) { activity in
                            ActivityRow(
                                activity: activity,
                                activityStore: activityStore
                            )
                        }
                    }
                    .padding(.horizontal)
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
                    NavigationLink(destination: SettingsView(activityStore: activityStore)) {
                        Image(systemName: "gearshape.fill")
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
                AddActivitySheet(isPresented: $showingAddActivity) { name, mode in
                    activityStore.addActivity(name: name, mode: mode)
                    activityStore.ensureTodayActivityExists(for: name, mode: mode)
                }
            }
            .sheet(isPresented: $showingHistoricalInput) {
                HistoricalInputView(
                    isPresented: $showingHistoricalInput,
                    activityStore: activityStore,
                    onSave: { name, date, duration, mode, count in
                        print("ContentView received save: \(name), mode: \(mode), duration: \(duration), count: \(count)")
                        activityStore.addActivity(
                            name: name,
                            mode: mode,
                            date: date,
                            duration: mode == .duration ? duration : 0,
                            count: mode == .count ? count : 0
                        )
                    }
                )
            }
            .sheet(isPresented: $showingTimeInput) {
                NavigationView {
                    TimeInputView(
                        activity: selectedActivity?.toActivity() ?? Activity(name: "", mode: .duration, timeSpent: 0, date: Date()),
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
                                    activityStore.addActivity(name: activity.name, mode: activity.mode, duration: timeInSeconds)
                                } else {
                                    // Update existing activity
                                    activity.timeSpent = timeInSeconds
                                    activityStore.saveContext()
                                    activityStore.objectWillChange.send()
                                }
                                selectedActivity = nil
                            }
                        }
                    )
                }
            }
        }
        .onAppear {
            activityStore.setModelContext(modelContext)
        }
    }
}

// Settings View
struct SettingsView: View {
    @ObservedObject var activityStore: ActivityStore
    @State private var showingReminderSettings = false
    @State private var showingExportSheet = false
    @State private var exportURL: URL?
    @State private var isGeneratingCSV = false
    
    var body: some View {
        List {
            Section(header: Text("Notifications")) {
                Button(action: { showingReminderSettings = true }) {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.blue)
                        Text("Daily Reminder")
                        Spacer()
                        Text(formatTime(activityStore.dailyReminderTime))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("Data")) {
                Button(action: {
                    isGeneratingCSV = true
                    // Use async to prevent UI blocking
                    Task {
                        if let url = activityStore.exportToCSV() {
                            await MainActor.run {
                                exportURL = url
                                showingExportSheet = true
                                isGeneratingCSV = false
                            }
                        } else {
                            await MainActor.run {
                                isGeneratingCSV = false
                            }
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                        Text("Export Data")
                        if isGeneratingCSV {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                    }
                }
                .disabled(isGeneratingCSV)
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showingReminderSettings) {
            ReminderSettingsView(
                reminderTime: activityStore.dailyReminderTime,
                onSave: { newTime in
                    activityStore.updateReminderTime(newTime)
                    showingReminderSettings = false
                }
            )
        }
        .sheet(isPresented: $showingExportSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
        .overlay {
            if isGeneratingCSV {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(1.5)
                    Text("Generating CSV file...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground).opacity(0.8))
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// ShareSheet for exporting files
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .modelContainer(for: PersistentActivity.self)
    }
} 