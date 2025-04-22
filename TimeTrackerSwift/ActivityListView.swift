import SwiftUI
import SwiftData

struct ActivityListView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var activityStore: ActivityStore
    @State private var showingAddActivity = false
    @State private var newActivityName = ""
    
    init() {
        _activityStore = StateObject(wrappedValue: ActivityStore())
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(activityStore.activities, id: \.startTime) { activity in
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
                        TextField("Activity Name", text: $newActivityName)
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
        activityStore.addActivity(name: newActivityName)
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