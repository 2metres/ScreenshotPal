import SwiftUI

struct ScreenshotGrid: View {
    let screenshots: [Screenshot]
    @Binding var selectedID: UUID?

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(screenshots) { screenshot in
                ScreenshotThumbnail(
                    screenshot: screenshot,
                    isSelected: selectedID == screenshot.id,
                    onSelect: { selectedID = screenshot.id }
                )
            }
        }
    }
}
