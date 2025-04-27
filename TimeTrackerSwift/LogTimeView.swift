import SwiftUI
import SwiftData

struct LogTimeView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var activityStore: ActivityStore
    let activity: PersistentActivity
    
    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    @State private var selectedDate: Date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Log time for \(activity.name)")) {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                    
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
                }
            }
            .navigationTitle("Log Time")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    saveTime()
                }
            )
        }
    }
    
    private func saveTime() {
        let totalSeconds = TimeInterval(hours * 3600 + minutes * 60)
        activityStore.addActivity(name: activity.name, date: selectedDate, duration: totalSeconds)
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PersistentActivity.self, configurations: config)
    
    let activity = PersistentActivity(
        name: "Sample Activity",
        startTime: Date(),
        timeSpent: 3600
    )
    
    let store = ActivityStore()
    store.setModelContext(container.mainContext)
    
    return LogTimeView(activityStore: store, activity: activity)
} 