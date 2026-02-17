import Foundation

public enum BeaconError: Error, Equatable, Sendable {
    case noTargetsProvided
    case targetsNotRegistered([String])
}

extension BeaconError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noTargetsProvided:
            "No target identifiers provided"
        case .targetsNotRegistered(let ids):
            "Targets not registered: \(ids.joined(separator: ", "))"
        }
    }
}
