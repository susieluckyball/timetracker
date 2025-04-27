import SwiftUI
import SwiftData

struct ActivityListView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var activityStore: ActivityStore
    @State private var showingAddActivity = false
    @State private var newActivityName = ""
    @State private var mode: ActivityMode = .duration
    
    init() {
        _activityStore = StateObject(wrappedValue: ActivityStore())
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(activityStore.activities, id: \.id) { activity in
                    ActivityRow(activity: activity, activityStore: activityStore)
                }
                .onDelete(perform: deleteActivity)
            }
            .navigationTitle("Activities")
            .toolbar {
                Button(action: { showingAddActivity = true }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingAddActivity) {
                NavigationStack {
                    Form {
                        Section(header: Text("New Activity")) {
                            TextField("Activity Name", text: $newActivityName)
                            
                            Picker("Mode", selection: $mode) {
                                Text("Duration").tag(ActivityMode.duration)
                                Text("Count").tag(ActivityMode.count)
                            }
                        }
                    }
                    .navigationTitle("New Activity")
                    .navigationBarItems(
                        leading: Button("Cancel") {
                            showingAddActivity = false
                            newActivityName = ""
                        },
                        trailing: Button("Add") {
                            addActivity()
                            showingAddActivity = false
                            newActivityName = ""
                        }
                        .disabled(newActivityName.isEmpty)
                    )
                }
            }
        }
        .onAppear {
            activityStore.setModelContext(modelContext)
        }
    }
    
    private func addActivity() {
        activityStore.addActivity(name: newActivityName, mode: mode)
    }
    
    private func deleteActivity(at offsets: IndexSet) {
        for index in offsets {
            activityStore.deleteActivity(activityStore.activities[index])
        }
    }
}

#Preview {
    let preview = try! ModelContainer(for: PersistentActivity.self)
    ActivityListView()
        .modelContainer(preview)
} 
