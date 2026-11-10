import SwiftUI

@main
struct FileDeckApp: App {
    var body: some Scene {
        WindowGroup {
            DualPaneView()
                .frame(minWidth: 1080, minHeight: 680)
        }
    }
}

struct DualPaneView: View {
    @StateObject private var left = BrowserModel()
    @StateObject private var right = BrowserModel()

    var body: some View {
        HStack(spacing: 0) {
            BrowserPane(model: left)
                .frame(maxWidth: .infinity)

            Divider()
                .frame(width: 1)

            BrowserPane(model: right)
                .frame(maxWidth: .infinity)
        }
    }
}

struct BrowserPane: View {
    @ObservedObject var model: BrowserModel

    var body: some View {
        VStack(spacing: 0) {
            AddressBar(model: model)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            FileListView(model: model)

            StatusBar(model: model)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
        }
    }
}
