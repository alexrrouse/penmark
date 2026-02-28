import SwiftUI

struct TabBarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(appState.openTabs) { tab in
                    TabItemView(tab: tab)
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 36)
        .background(Material.bar)
        .overlay(Divider(), alignment: .bottom)
    }
}

struct TabItemView: View {
    let tab: FileTab
    @EnvironmentObject var appState: AppState
    @State private var isHovered = false

    private var isActive: Bool { appState.activeTabID == tab.id }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "doc.text")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            Text(tab.fileItem.name)
                .font(.system(size: 12))
                .lineLimit(1)
                .frame(maxWidth: 140)

            Button {
                appState.closeTab(id: tab.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 16, height: 16)
                    .background(
                        Circle()
                            .fill(isHovered ? Color(nsColor: .quaternaryLabelColor) : Color.clear)
                    )
            }
            .buttonStyle(.plain)
            .opacity(isHovered || isActive ? 1 : 0)
        }
        .padding(.horizontal, 10)
        .frame(height: 34)
        .background(
            Rectangle()
                .fill(isActive ? Color(nsColor: .controlBackgroundColor) : Color.clear)
        )
        .overlay(
            Rectangle()
                .frame(height: 2)
                .foregroundStyle(isActive ? Color.accentColor : Color.clear),
            alignment: .bottom
        )
        .contentShape(Rectangle())
        .onTapGesture { appState.activeTabID = tab.id }
        .onHover { isHovered = $0 }
    }
}
