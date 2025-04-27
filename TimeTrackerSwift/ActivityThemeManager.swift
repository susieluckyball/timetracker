import SwiftUI

struct ActivityThemeManager {
    let color: Color
    let icon: String
    
    init(color: Color, icon: String) {
        self.color = color
        self.icon = icon
    }
    
    static let themes: [String: ActivityThemeManager] = [
        "Reading": ActivityThemeManager(color: .blue, icon: "book.fill"),
        "Work": ActivityThemeManager(color: .orange, icon: "briefcase.fill"),
        "Personal Interest": ActivityThemeManager(color: .purple, icon: "graduationcap.fill"),
        "Gaming": ActivityThemeManager(color: .red, icon: "gamecontroller.fill"),
        "Meditation": ActivityThemeManager(color: .teal, icon: "leaf.fill"),
        "Music": ActivityThemeManager(color: .pink, icon: "music.note"),
        "Art": ActivityThemeManager(color: .indigo, icon: "paintbrush.fill"),
        "Cooking": ActivityThemeManager(color: .yellow, icon: "fork.knife"),
        "Sleep": ActivityThemeManager(color: .gray, icon: "moon.fill"),
        "Podcast": ActivityThemeManager(color: .purple, icon: "headphones"),
        "Gym": ActivityThemeManager(color: .red, icon: "figure.run"),
        "English": ActivityThemeManager(color: .blue, icon: "globe")
    ]
    
    static func getTheme(for activityName: String) -> ActivityThemeManager {
        // Default theme for activities not in the predefined list
        let defaultTheme = ActivityThemeManager(color: .blue, icon: "star.fill")
        
        // Check if the activity name contains any of our known keywords
        for (keyword, theme) in themes {
            if activityName.lowercased().contains(keyword.lowercased()) {
                return theme
            }
        }
        
        return defaultTheme
    }
} 