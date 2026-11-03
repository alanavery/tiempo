import EventKit
import Foundation

struct CalendarEventSnapshot: Equatable {
    var title: String
    var start: Date
    var end: Date
}

enum CalendarAuthorization: Equatable {
    case fullAccess
    case writeOnly
    case denied
    case restricted
    case notDetermined
    case unknown

    var isGranted: Bool {
        self == .fullAccess
    }

    var statusLabel: String {
        switch self {
        case .fullAccess:
            "Calendar access granted"
        case .writeOnly:
            "Write-only access; full access required"
        case .denied:
            "Calendar access denied in System Settings"
        case .restricted:
            "Calendar access restricted"
        case .notDetermined:
            "Calendar access required"
        case .unknown:
            "Calendar access unavailable"
        }
    }

    static func current() -> CalendarAuthorization {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess:
            .fullAccess
        case .writeOnly:
            .writeOnly
        case .denied:
            .denied
        case .restricted:
            .restricted
        case .notDetermined:
            .notDetermined
        @unknown default:
            .unknown
        }
    }
}

@MainActor
protocol CalendarEventSource: AnyObject {
    var authorization: CalendarAuthorization { get }
    func requestAccess() async -> Bool
    func timedEvents(on calendarNamed: String, spanning date: Date) -> [CalendarEventSnapshot]
}

extension CalendarEventSource {
    var authorizationGranted: Bool {
        authorization.isGranted
    }
}
