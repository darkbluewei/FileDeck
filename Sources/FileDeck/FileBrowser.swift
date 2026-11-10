import AppKit
import SwiftUI

struct FileItem: Identifiable, Hashable {
    let url: URL
    let name: String
    let isDirectory: Bool
    let size: Int64?
    let modifiedAt: Date?

    var id: URL { url }
}

@MainActor
final class BrowserModel: ObservableObject {
    @Published var currentURL: URL = FileManager.default.homeDirectoryForCurrentUser
    @Published var items: [FileItem] = []
    @Published var selection: Set<URL> = []
    @Published var selectionSize: Int64 = 0
    @Published var isCalculatingSize = false
    @Published var statusText = ""

    private let fileManager = FileManager.default

    var homeURL: URL {
        fileManager.homeDirectoryForCurrentUser
    }

    func load() {
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: currentURL,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
                options: []
            )

            let loaded = contents.map { itemURL in
                let values = try? itemURL.resourceValues(forKeys: [
                    .isDirectoryKey, .fileSizeKey, .contentModificationDateKey
                ])

                return FileItem(
                    url: itemURL,
                    name: itemURL.lastPathComponent,
                    isDirectory: values?.isDirectory ?? false,
                    size: values?.fileSize.map(Int64.init),
                    modifiedAt: values?.contentModificationDate
                )
            }
            .sorted {
                if $0.isDirectory != $1.isDirectory {
                    return $0.isDirectory
                }
                return $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }

            items = loaded
            selection = []
            selectionSize = 0
            statusText = "\(loaded.count) items"
        } catch {
            items = []
            statusText = error.localizedDescription
        }
    }

    func open(_ item: FileItem) {
        if item.isDirectory {
            navigate(to: item.url)
        } else {
            NSWorkspace.shared.open(item.url)
        }
    }

    func navigate(to url: URL) {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            statusText = "Folder not found: \(url.path)"
            return
        }

        currentURL = url.standardizedFileURL
        load()
    }

    func goUp() {
        let parent = currentURL.deletingLastPathComponent()
        guard parent.path != currentURL.path else { return }
        navigate(to: parent)
    }

    func goHome() {
        navigate(to: homeURL)
    }

    func revealInFinder() {
        let urls = Array(selection)
        guard !urls.isEmpty else { return }
        NSWorkspace.shared.activateFileViewerSelecting(urls)
    }

    func calculateSelectionSize() {
        let urls = Array(selection)
        guard !urls.isEmpty else {
            selectionSize = 0
            isCalculatingSize = false
            return
        }

        isCalculatingSize = true

        Task.detached(priority: .userInitiated) { [weak self] in
            var total: Int64 = 0

            for url in urls {
                total += await Self.folderSize(at: url)
            }

            await MainActor.run {
                self?.selectionSize = total
                self?.isCalculatingSize = false
            }
        }
    }

    nonisolated private static func folderSize(at url: URL) async -> Int64 {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return 0
        }

        if !isDirectory.boolValue {
            let values = try? url.resourceValues(forKeys: [.fileSizeKey])
            return Int64(values?.fileSize ?? 0)
        }

        let keys: [URLResourceKey] = [.isDirectoryKey, .fileSizeKey]
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        var total: Int64 = 0

        for case let itemURL as URL in enumerator {
            let values = try? itemURL.resourceValues(forKeys: Set(keys))
            if values?.isDirectory == false {
                total += Int64(values?.fileSize ?? 0)
            }
        }

        return total
    }
}

struct FileListView: View {
    @ObservedObject var model: BrowserModel

    var body: some View {
        List(selection: Binding(
            get: { model.selection },
            set: { newValue in
                model.selection = newValue
                model.calculateSelectionSize()
            }
        )) {
            ForEach(model.items) { item in
                FileRow(item: item)
                    .tag(item.url)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        model.open(item)
                    }
            }
        }
        .listStyle(.plain)
        .overlay {
            if model.items.isEmpty {
                ContentUnavailableView(
                    "No Items",
                    systemImage: "folder",
                    description: Text("This folder is empty or cannot be accessed.")
                )
            }
        }
    }
}

struct FileRow: View {
    let item: FileItem

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.isDirectory ? "folder.fill" : "doc")
                .foregroundStyle(item.isDirectory ? .blue : .secondary)
                .frame(width: 20)

            Text(item.name)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            if !item.isDirectory {
                Text(ByteCountFormatter.string(fromByteCount: item.size ?? 0, countStyle: .file))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            if let date = item.modifiedAt {
                Text(date, style: .date)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 2)
    }
}
