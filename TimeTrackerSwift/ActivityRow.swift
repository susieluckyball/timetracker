import SwiftUI
import SwiftData

struct ActivityRow: View {
    let activity: PersistentActivity
    @ObservedObject var activityStore: ActivityStore
    @State private var isTracking = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(activity.name)
                    .font(.headline)
                if activity.isActive {
                    Text("Started: \(activity.startTime.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: toggleTracking) {
                Image(systemName: isTracking ? "stop.circle.fill" : "play.circle.fill")
                    .font(.title)
                    .foregroundColor(isTracking ? .red : .green)
            }
        }
        .onAppear {
            isTracking = activity.isActive
        }
    }
    
    private func toggleTracking() {
        if isTracking {
            activityStore.stopTracking(activity)
        } else {
            activityStore.startTracking(activity)
        }
        isTracking.toggle()
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: PersistentActivity.self, configurations: config)
        let activity = PersistentActivity(name: "Sample Activity")
        let store = ActivityStore()
        store.setModelContext(container.mainContext)
        
        return ActivityRow(activity: activity, activityStore: store)
            .modelContainer(container)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
} 