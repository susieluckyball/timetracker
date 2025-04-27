import SwiftUI
import SwiftData

struct AddActivityView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var mode: ActivityMode = .duration
    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    @State private var count: Int = 0
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Activity Details")) {
                    TextField("Activity Name", text: $name)
                    
                    Picker("Mode", selection: $mode) {
                        Text("Duration").tag(ActivityMode.duration)
                        Text("Count").tag(ActivityMode.count)
                    }
                }
                
                if mode == .duration {
                    Section(header: Text("Duration")) {
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
                } else {
                    Section(header: Text("Count")) {
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
            .navigationTitle("Add Activity")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    saveActivity()
                }
                .disabled(name.isEmpty)
            )
        }
    }
    
    private func saveActivity() {
        let timeSpent = TimeInterval(hours * 3600 + minutes * 60)
        let activity = Activity(
            name: name,
            mode: mode,
            timeSpent: timeSpent,
            count: count,
            date: Date()
        )
        
        modelContext.insert(activity)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Activity.self, configurations: config)
    
    return AddActivityView()
        .modelContainer(container)
} 