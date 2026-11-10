import SwiftUI

struct AddressBar: View {
    @ObservedObject var model: BrowserModel
    @State private var pathText = ""
    @FocusState private var isEditing: Bool

    var body: some View {
        HStack(spacing: 8) {
            Button {
                model.goUp()
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(model.currentURL == model.homeURL)

            Button {
                model.goHome()
            } label: {
                Image(systemName: "house")
            }

            TextField("Enter a folder path", text: $pathText)
                .textFieldStyle(.plain)
                .focused($isEditing)
                .submitLabel(.go)
                .onSubmit {
                    navigate()
                }
                .onAppear {
                    pathText = model.currentURL.path
                }
                .onChange(of: model.currentURL) { _, newValue in
                    pathText = newValue.path
                }

            Button {
                navigate()
            } label: {
                Image(systemName: "arrow.right.circle")
            }
            .disabled(pathText.isEmpty)
        }
        .padding(8)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
    }

    private func navigate() {
        var path = pathText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !path.isEmpty else { return }

        if path.hasPrefix("~") {
            path = NSString(string: path).expandingTildeInPath
        }

        let url = URL(fileURLWithPath: path, isDirectory: true)
        model.navigate(to: url)
        isEditing = false
    }
}

struct StatusBar: View {
    @ObservedObject var model: BrowserModel

    private var selectionCount: Int {
        model.selection.count
    }

    var body: some View {
        HStack(spacing: 12) {
            if selectionCount == 0 {
                Text(model.statusText)
                    .foregroundStyle(.secondary)
            } else {
                Text("Selected \(selectionCount) item\(selectionCount == 1 ? "" : "s")")
                    .fontWeight(.medium)

                if model.isCalculatingSize {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text(ByteCountFormatter.string(
                        fromByteCount: model.selectionSize,
                        countStyle: .file
                    ))
                    .monospacedDigit()
                }
            }

            Spacer()

            Button("Reveal in Finder") {
                model.revealInFinder()
            }
            .buttonStyle(.borderless)
            .disabled(model.selection.isEmpty)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}
