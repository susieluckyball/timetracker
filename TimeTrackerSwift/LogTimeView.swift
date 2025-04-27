import SwiftUI
import SwiftData

struct LogTimeView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var activityStore: ActivityStore
    let activity: PersistentActivity
    
    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    @State private var count: Int = 0
    @State private var selectedDate: Date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Log \(activity.mode == .duration ? "time" : "count") for \(activity.name)")) {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                    
                    if activity.mode == .duration {
                        HStack {
                            Text("Hours")
                            Spacer()
                            TextField("0", value: $hours, formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                        }
                        
                        HStack {
                            Text("Minutes")
                            Spacer()
                            TextField("0", value: $minutes, formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                        }
                    } else {
                        HStack {
                            Text("Count")
                            Spacer()
                            TextField("0", value: $count, formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                        }
                    }
                }
            }
            .navigationTitle(activity.mode == .duration ? "Log Time" : "Log Count")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    saveValue()
                }
            )
        }
    }
    
    private func saveValue() {
        if activity.mode == .duration {
            let totalSeconds = TimeInterval(hours * 3600 + minutes * 60)
            activityStore.addActivity(
                name: activity.name,
                mode: activity.mode,
                date: selectedDate,
                duration: totalSeconds
            )
        } else {
            activityStore.addActivity(
                name: activity.name,
                mode: activity.mode,
                date: selectedDate,
                count: count
            )
        }
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PersistentActivity.self, configurations: config)
    
    let activity = PersistentActivity(
        name: "Sample Activity",
        mode: .duration,
        startTime: Date(),
        timeSpent: 3600
    )
    
    let store = ActivityStore()
    store.setModelContext(container.mainContext)
    
    return LogTimeView(activityStore: store, activity: activity)
} 