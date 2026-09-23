import SwiftUI
import SwiftData

@main
struct NowNestApp: App {
    private let modelContainer: ModelContainer
    private let visualVariantConfiguration: VisualVariantConfiguration
    private let recoveryNotice: String?

    init() {
        let schema = Schema([NowContext.self, ParkedIdea.self, DogfoodEvent.self])
        let arguments = ProcessInfo.processInfo.arguments
        let isDebug: Bool = {
            #if DEBUG
            return true
            #else
            return false
            #endif
        }()
        let storedQuietMode = UserDefaults.standard.bool(forKey: "quietModeEnabled")
        visualVariantConfiguration = VisualVariantLaunchParser.resolve(
            arguments: arguments,
            storedQuietMode: storedQuietMode,
            isDebug: isDebug
        )

        var notice: String?
        do {
            if arguments.contains("-ui-testing") {
                modelContainer = try ModelContainer(
                    for: schema,
                    configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                )
            } else if arguments.contains("-ui-testing-persistent-reset") {
                let url = Self.uiTestingStoreURL
                Self.removeStore(at: url)
                modelContainer = try ModelContainer(
                    for: schema,
                    configurations: ModelConfiguration(schema: schema, url: url)
                )
            } else if arguments.contains("-ui-testing-persistent") {
                modelContainer = try ModelContainer(
                    for: schema,
                    configurations: ModelConfiguration(schema: schema, url: Self.uiTestingStoreURL)
                )
            } else {
                let result = try Self.createRecoverableModelContainer(for: schema)
                modelContainer = result.container
                if result.recoveryURL != nil {
                    notice = "Your local store could not be opened. NowNest preserved a recovery copy and started a new local store."
                }
            }
        } catch {
            fatalError("Unable to create NowNest model container: \(error)")
        }
        recoveryNotice = notice
    }

    private static var uiTestingStoreURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("NowNest-ui-testing.store")
    }

    private static func removeStore(at url: URL) {
        let fileManager = FileManager.default
        for suffix in ["", "-shm", "-wal"] {
            try? fileManager.removeItem(at: URL(fileURLWithPath: url.path + suffix))
        }
    }

    private static func createRecoverableModelContainer(for schema: Schema) throws -> (container: ModelContainer, recoveryURL: URL?) {
        do {
            return (try ModelContainer(for: schema), nil)
        } catch {
            let storeURL = FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("default.store")
            let recoveryURL = try preserveStore(at: storeURL)
            return (try ModelContainer(for: schema), recoveryURL)
        }
    }

    static func recoverFromCorruptedStore(at storeURL: URL, schema: Schema) throws -> (ModelContainer, URL?) {
        let recoveryURL = try preserveStore(at: storeURL)
        return (try ModelContainer(for: schema), recoveryURL)
    }

    private static func preserveStore(at storeURL: URL) throws -> URL? {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: storeURL.path) else { return nil }

        let recoveryDirectory = storeURL.deletingLastPathComponent()
            .appendingPathComponent("NowNest Recovery", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: recoveryDirectory, withIntermediateDirectories: true)

        for suffix in ["", "-shm", "-wal"] {
            let source = URL(fileURLWithPath: storeURL.path + suffix)
            guard fileManager.fileExists(atPath: source.path) else { continue }
            try fileManager.moveItem(
                at: source,
                to: recoveryDirectory.appendingPathComponent(source.lastPathComponent)
            )
        }
        return recoveryDirectory
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.visualVariantConfiguration, visualVariantConfiguration)
                .environment(\.recoveryNotice, recoveryNotice)
        }
        .modelContainer(modelContainer)
    }
}

extension EnvironmentValues {
    @Entry var recoveryNotice: String? = nil
}
