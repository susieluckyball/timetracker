import SwiftUI

struct AppIcon: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.2, green: 0.6, blue: 1.0),
                    Color(red: 0.4, green: 0.8, blue: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Timer circle
            Circle()
                .strokeBorder(Color.white, lineWidth: 8)
                .frame(width: 80, height: 80)
            
            // Timer hand
            Rectangle()
                .fill(Color.white)
                .frame(width: 4, height: 35)
                .offset(y: -10)
                .rotationEffect(.degrees(-45))
            
            // Center dot
            Circle()
                .fill(Color.white)
                .frame(width: 12, height: 12)
            
            // Small dots around the circle
            ForEach(0..<12) { index in
                Circle()
                    .fill(Color.white)
                    .frame(width: 6, height: 6)
                    .offset(y: -45)
                    .rotationEffect(.degrees(Double(index) * 30))
            }
        }
        .frame(width: 1024, height: 1024) // Largest required size
    }
}

struct IconPreview: View {
    var body: some View {
        AppIcon()
            .previewLayout(.sizeThatFits)
    }
}

struct IconPreview_Previews: PreviewProvider {
    static var previews: some View {
        IconPreview()
    }
} 