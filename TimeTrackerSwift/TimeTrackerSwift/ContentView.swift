import SwiftUI

struct ContentView: View {
    @StateObject private var activityStore = ActivityStore()
    @State private var newActivityName = ""
    @State private var showingTimeInput = false
    @State private var selectedActivity: Activity?
    @State private var timeInput: String = ""
    @State private var showingReminderSettings = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Activity Input
                HStack {
                    TextField("Enter activity name", text: $newActivityName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: addActivity) {
                        Text("Add")
                            .padding(.horizontal)
                    }
                }
                .padding()
                
                // Activities List
                List {
                    ForEach(activityStore.activities) { activity in
                        ActivityRow(activity: activity)
                            .onTapGesture {
                                selectedActivity = activity
                                showingTimeInput = true
                            }
                    }
                }
                
                // Stats Button
                NavigationLink(destination: StatsView(activities: activityStore.getWeeklyStats())) {
                    Text("View Weekly Stats")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
                
                // Reminder Settings Button
                Button(action: { showingReminderSettings = true }) {
                    Text("Reminder Settings")
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Time Tracker")
            .sheet(isPresented: $showingTimeInput, onDismiss: {
                selectedActivity = nil
            }) {
                if let activity = selectedActivity {
                    TimeInputView(activity: activity, onSave: { minutes in
                        let updatedActivity = Activity(
                            id: activity.id,
                            name: activity.name,
                            timeSpent: TimeInterval(minutes),
                            date: Date()
                        )
                        activityStore.addActivity(updatedActivity)
                        showingTimeInput = false
                    })
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
    
    private func addActivity() {
        guard !newActivityName.isEmpty else { return }
        let activity = Activity(name: newActivityName, timeSpent: 0, date: Date())
        activityStore.addActivity(activity)
        newActivityName = ""
    }
}

struct ActivityRow: View {
    let activity: Activity
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(activity.name)
                    .font(.headline)
                Text(activity.formattedTime)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
            Text(activity.date, style: .date)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}

struct TimeInputView: View {
    let activity: Activity
    let onSave: (Int) -> Void
    @State private var hours: String = ""
    @State private var minutes: String = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Log time for \(activity.name)")) {
                    HStack {
                        TextField("Hours", text: $hours)
                            .keyboardType(.numberPad)
                        Text("hours")
                    }
                    HStack {
                        TextField("Minutes", text: $minutes)
                            .keyboardType(.numberPad)
                        Text("minutes")
                    }
                }
            }
            .navigationTitle("Log Time")
            .navigationBarItems(
                trailing: Button("Save") {
                    let totalMinutes = (Int(hours) ?? 0) * 60 + (Int(minutes) ?? 0)
                    onSave(totalMinutes)
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

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

struct StatsView: View {
    let activities: [Activity]
    
    var body: some View {
        List {
            ForEach(activities) { activity in
                HStack {
                    Text(activity.name)
                    Spacer()
                    Text(activity.formattedTime)
                }
            }
        }
        .navigationTitle("Weekly Stats")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 
