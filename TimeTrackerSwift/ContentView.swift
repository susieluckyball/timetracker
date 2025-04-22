import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var activityStore: ActivityStore
    @State private var showingTimeInput = false
    @State private var showingAddActivity = false
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
                        
                        Text("Track Your Time ✨")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .padding(.leading, 2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Activities Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
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
                        .padding(.horizontal)
                        
                        // Today's Activities
                        ForEach(activityStore.todayActivities, id: \.startTime) { activity in
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
                    Text("Timekeeper")
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
            .sheet(isPresented: $showingTimeInput) {
                NavigationView {
                    TimeInputView(
                        activity: selectedActivity?.toActivity() ?? Activity(name: "", timeSpent: 0, date: Date()),
                        isPresented: $showingTimeInput,
                        onSave: { minutes in
                            if let activity = selectedActivity {
                                let timeInSeconds = TimeInterval(minutes * 60)
                                activity.endTime = Date().addingTimeInterval(timeInSeconds)
                                activityStore.stopTracking(activity)
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