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
        HStack {
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
                        Text(activity.toActivity().formattedValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .onTapGesture {
                                showingLogTime = true
                            }
                    }
                }
            }
            
            Spacer()
            
            Button {
                let currentActivity = activity.toActivity()
                switch currentActivity.mode {
                case .duration:
                    let newDuration = currentActivity.timeSpent + (15 * 60) // Add 15 minutes to existing duration
                    activityStore.addActivity(
                        name: activity.name,
                        mode: .duration,
                        date: activity.startTime,
                        duration: newDuration
                    )
                case .count:
                    activityStore.incrementCounter(for: activity)
                }
            } label: {
                Image(systemName: activity.mode == .duration ? "clock" : "plus.circle")
                    .font(.title2)
                    .foregroundColor(theme.color)
            }
        }
        .padding()
        .background(theme.color.opacity(0.1))
        .cornerRadius(12)
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
        mode: .duration,
        startTime: Date(), 
        timeSpent: 3600
    )
    
    let store = ActivityStore()
    store.setModelContext(container.mainContext)
    
    return ActivityRow(activity: activity, activityStore: store)
}
