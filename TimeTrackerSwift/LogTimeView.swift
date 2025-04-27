import SwiftUI
import SwiftData

struct LogTimeView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var activityStore: ActivityStore
    let activity: PersistentActivity
    
    @State private var selectedDuration: Int = 0 // in minutes
    @State private var selectedCount: Int = 0
    @State private var selectedDate: Date = Date()
    
    private let durationOptions = Array(stride(from: 0, through: 720, by: 5)) // 0 to 12 hours in 5-min increments
    private let countOptions = Array(0...100) // 0 to 100 counts
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Log \(activity.mode == .duration ? "time" : "count") for \(activity.name)")) {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                    
                    if activity.mode == .duration {
                        Picker("Duration", selection: $selectedDuration) {
                            ForEach(durationOptions, id: \.self) { minutes in
                                Text(formatDuration(minutes))
                            }
                        }
                        .pickerStyle(.wheel)
                    } else {
                        Picker("Count", selection: $selectedCount) {
                            ForEach(countOptions, id: \.self) { count in
                                Text("\(count)")
                            }
                        }
                        .pickerStyle(.wheel)
                    }
                }
            }
            .navigationTitle("Log \(activity.mode == .duration ? "Time" : "Count")")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    save()
                    dismiss()
                }
            )
        }
    }
    
    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(remainingMinutes)m"
        }
    }
    
    private func save() {
        if activity.mode == .duration {
            let durationInSeconds = TimeInterval(selectedDuration * 60)
            activityStore.addActivity(
                name: activity.name,
                mode: .duration,
                date: selectedDate,
                duration: durationInSeconds
            )
        } else {
            activityStore.addActivity(
                name: activity.name,
                mode: .count,
                date: selectedDate,
                count: selectedCount
            )
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PersistentActivity.self, configurations: config)
    
    let activity = PersistentActivity(
        name: "Reading",
        mode: .duration,
        startTime: Date(),
        timeSpent: 3600
    )
    
    let store = ActivityStore()
    store.setModelContext(container.mainContext)
    
    return LogTimeView(activityStore: store, activity: activity)
} 