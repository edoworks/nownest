import SwiftUI

enum VisualVariant: String, CaseIterable, Sendable {
    case control
    case expressive
    case sophie

    var showsSophie: Bool { self == .sophie }
}

enum QuietMode: String, CaseIterable, Sendable {
    case enabled
    case disabled
}

struct VisualVariantConfiguration: Sendable, Equatable {
    let variant: VisualVariant
    let quietMode: QuietMode

    static let control = VisualVariantConfiguration(variant: .control, quietMode: .disabled)

    var showsSophie: Bool {
        variant.showsSophie && quietMode == .disabled
    }

    var isQuiet: Bool {
        quietMode == .enabled
    }

    var showsReassurance: Bool {
        !isQuiet
    }

    var showsCaptureTitle: Bool {
        !isQuiet
    }

    var returnTargetPrefix: String {
        isQuiet ? "Back to: " : "After parking, return to: "
    }

    func confirmationCopy(for nextAction: String) -> String {
        switch variant {
        case .control:
            return "Parked. Back to \(nextAction)."
        case .expressive:
            return "Tucked away. Back to: \(nextAction)."
        case .sophie:
            if quietMode == .enabled {
                return "Tucked away. Back to: \(nextAction)."
            }
            return "Sophie tucked it away. Back to: \(nextAction)."
        }
    }
}

enum VisualVariantLaunchParser {
    enum ParseError: Error, Equatable {
        case missingValue(option: String)
        case duplicateOption(option: String)
        case unsupportedValue(option: String, value: String)
    }

    struct ParseResult: Equatable, Sendable {
        let variant: VisualVariant?
        let quietMode: QuietMode?
    }

    static func parse(arguments: [String], failFast: Bool) throws -> ParseResult {
        var variantValue: String?
        var quietModeValue: String?
        var variantSeen = false
        var quietModeSeen = false

        var index = 0
        while index < arguments.count {
            let arg = arguments[index]
            if arg == "-visual-variant" {
                if variantSeen {
                    if failFast { throw ParseError.duplicateOption(option: arg) }
                } else {
                    variantSeen = true
                    guard index + 1 < arguments.count else {
                        if failFast { throw ParseError.missingValue(option: arg) }
                        index += 1
                        continue
                    }
                    variantValue = arguments[index + 1]
                    index += 2
                    continue
                }
            } else if arg == "-quiet-mode" {
                if quietModeSeen {
                    if failFast { throw ParseError.duplicateOption(option: arg) }
                } else {
                    quietModeSeen = true
                    guard index + 1 < arguments.count else {
                        if failFast { throw ParseError.missingValue(option: arg) }
                        index += 1
                        continue
                    }
                    quietModeValue = arguments[index + 1]
                    index += 2
                    continue
                }
            }
            index += 1
        }

        let resolvedVariant = try resolveVariant(value: variantValue, failFast: failFast)
        let resolvedQuietMode = try resolveQuietMode(value: quietModeValue, failFast: failFast)

        return ParseResult(variant: resolvedVariant, quietMode: resolvedQuietMode)
    }

    private static func resolveVariant(value: String?, failFast: Bool) throws -> VisualVariant? {
        guard let value else { return nil }
        guard let variant = VisualVariant(rawValue: value) else {
            if failFast {
                throw ParseError.unsupportedValue(option: "-visual-variant", value: value)
            }
            return .control
        }
        return variant
    }

    private static func resolveQuietMode(value: String?, failFast: Bool) throws -> QuietMode? {
        guard let value else { return nil }
        guard let mode = QuietMode(rawValue: value) else {
            if failFast {
                throw ParseError.unsupportedValue(option: "-quiet-mode", value: value)
            }
            return nil
        }
        return mode
    }

    static func resolve(
        arguments: [String],
        storedQuietMode: Bool,
        isDebug: Bool
    ) -> VisualVariantConfiguration {
        let result: ParseResult
        do {
            result = try parse(arguments: arguments, failFast: isDebug)
        } catch {
            if isDebug {
                fatalError("Invalid visual variant launch configuration: \(error)")
            }
            result = ParseResult(variant: .control, quietMode: nil)
        }

        let variant = result.variant ?? .control
        let quietMode = result.quietMode ?? (storedQuietMode ? .enabled : .disabled)

        return VisualVariantConfiguration(variant: variant, quietMode: quietMode)
    }
}

extension EnvironmentValues {
    @Entry var visualVariantConfiguration: VisualVariantConfiguration = .control
}