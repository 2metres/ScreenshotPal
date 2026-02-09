import SwiftUI

struct ScreenshotThumbnail: View {
    let screenshot: Screenshot
    let isSelected: Bool
    let onSelect: () -> Void
    @State private var isHovering = false

    var body: some View {
        Group {
            if let image = screenshot.image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 90, height: 90)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 90, height: 90)
                    .overlay(ProgressView().scaleEffect(0.5))
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : (isHovering ? Color.accentColor.opacity(0.5) : Color.clear), lineWidth: 2)
        )
        .onHover { hovering in
            isHovering = hovering
        }
        .onDrag {
            NSItemProvider(object: screenshot.url as NSURL)
        }
        .onTapGesture(count: 2) {
            NSWorkspace.shared.open(screenshot.url)
        }
        .onTapGesture(count: 1) {
            onSelect()
        }
        .help(screenshot.filename)
    }
}
