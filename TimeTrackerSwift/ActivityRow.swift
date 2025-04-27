import SwiftUI
import SwiftData

struct ActivityRow: View {
    let activity: PersistentActivity
    @ObservedObject var activityStore: ActivityStore
    @State private var showingLogTime = false
    
    private var theme: ActivityThemeManager {
        ActivityThemeManager.getTheme(for: activity.name)
    }
    
    var body: some View {
        NavigationLink(destination: ActivityDetailView(
            activity: activity,
            weeklyData: activityStore.getWeeklyStats(for: activity),
            activityStore: activityStore
        )) {
            HStack {
                Image(systemName: theme.icon)
                    .font(.title2)
                    .foregroundColor(theme.color)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.name)
                        .font(.headline)
                    Text(activity.toActivity().formattedTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { showingLogTime = true }) {
                    Image(systemName: "clock")
                        .font(.title2)
                        .foregroundColor(theme.color)
                }
            }
            .padding()
            .background(theme.color.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingLogTime) {
            LogTimeView(activityStore: activityStore, activity: activity)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PersistentActivity.self, configurations: config)
    
    let activity = PersistentActivity(
        name: "Reading", 
        startTime: Date(), 
        timeSpent: 3600
    )
    
    let store = ActivityStore()
    store.setModelContext(container.mainContext)
    
    return ActivityRow(activity: activity, activityStore: store)
}