import SwiftUI
import SwiftData

@main
struct NowNestApp: App {
    private let modelContainer: ModelContainer
    private let visualVariantConfiguration: VisualVariantConfiguration

    init() {
        let schema = Schema([NowContext.self, ParkedIdea.self])
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
                modelContainer = try Self.createRecoverableModelContainer(for: schema)
            }
        } catch {
            fatalError("Unable to create NowNest model container: \(error)")
        }
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

    private static func createRecoverableModelContainer(for schema: Schema) throws -> ModelContainer {
        do {
            return try ModelContainer(for: schema)
        } catch {
            let storeURL = FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("default.store")
            removeStore(at: storeURL)
            return try ModelContainer(for: schema)
        }
    }

    static func recoverFromCorruptedStore(at storeURL: URL, schema: Schema) throws -> ModelContainer {
        removeStore(at: storeURL)
        return try ModelContainer(for: schema)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.visualVariantConfiguration, visualVariantConfiguration)
        }
        .modelContainer(modelContainer)
    }
}
