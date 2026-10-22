import Foundation
import CalendarCore
import CalendarAccess
import CalendarNotifications
import MenuBar

/// Synthetic injection only. No EventKit, login registration or user settings access.
actor QACalendarBackend: CalendarBackend {
    let events: [EventOccurrence]
    init(now: Date = Date()) {
        let context = CalendarContext(timeZone: .current)
        let today = context.calendar.startOfDay(for: now)
        let color = RGBAColor(red: 0.2, green: 0.45, blue: 0.8)
        func event(_ id: String, _ title: String, _ start: Date, allDay: Bool = false, recurring: Bool = false, end: Date? = nil) -> EventOccurrence {
            EventOccurrence(calendarID: "qa-calendar", calendarName: "QA Sample", color: color, eventID: id, title: title, start: start, end: end ?? start.addingTimeInterval(allDay ? 86400 : 3600), isAllDay: allDay, isRecurring: recurring, originalOccurrence: recurring ? .timed(start) : nil, confirmedSeriesKey: recurring ? "qa-series" : nil)
        }
        events = [
            event("qa-soon", "QA event starting soon", now.addingTimeInterval(180)),
            event("qa-timed", "QA timed event", now.addingTimeInterval(7200)),
            event("qa-recurring", "QA recurring event", now.addingTimeInterval(10800), recurring: true),
            event("qa-recurring", "QA recurring event", now.addingTimeInterval(86400 + 10800), recurring: true),
            event("qa-allday", "QA all-day event", today.addingTimeInterval(86400), allDay: true),
            event("qa-long-title", "QA long title · a synthetic event whose title wraps across several lines to check the layout and reading order of the title and reminder button", now.addingTimeInterval(14400)),
            event("qa-multiday-allday", "QA multi-day all-day event", context.calendar.date(byAdding: .day, value: -1, to: today)!, allDay: true, end: context.calendar.date(byAdding: .day, value: 2, to: today)!),
            event("qa-multiday-timed", "QA multi-day timed event", context.calendar.date(byAdding: .hour, value: -6, to: today)!, end: context.calendar.date(byAdding: .hour, value: 30, to: today)!),
            EventOccurrence(calendarID: "qa-calendar-secondary", calendarName: "QA Second Calendar", color: .init(red: 0.8, green: 0.35, blue: 0.2), eventID: "qa-secondary", title: "QA selection scope event", start: now.addingTimeInterval(18000), end: now.addingTimeInterval(21600), isAllDay: false),
            event("qa-fixed", "QA fixed-date event", context.calendar.date(from: DateComponents(year: 2026, month: 10, day: 15, hour: 14))!)
        ]
    }
    func permission() async -> CalendarPermission { .authorized }
    func requestAccess() async throws {}
    func calendars() async throws -> [CalendarDescriptor] {
        [
            .init(id: "qa-calendar", name: "QA Sample", sourceName: "Synthetic Data", color: .init(red: 0.2, green: 0.45, blue: 0.8)),
            .init(id: "qa-calendar-secondary", name: "QA Second Calendar", sourceName: "Synthetic Data", color: .init(red: 0.8, green: 0.35, blue: 0.2))
        ]
    }
    func events(interval: DateInterval, calendarIDs: Set<String>) async throws -> [EventOccurrence] { events.filter { calendarIDs.contains($0.calendarID) && $0.start < interval.end && $0.end > interval.start } }
    func resolve(identity: ReminderIdentity, anchor: OccurrenceAnchor?, isRecurring: Bool, searchInterval: DateInterval?, calendarIDs: Set<String>) async throws -> CalendarEventResolution {
        guard calendarIDs.contains(identity.calendarID) else { return .outsideSelectedScope }
        let matches = events.filter { identity.matchesOccurrenceItem($0.reminderIdentity) && (!isRecurring || $0.originalOccurrence == anchor) }
        return matches.count == 1 ? .found(matches[0]) : matches.isEmpty ? .missing : .needsConfirmation
    }
}
@MainActor final class QASelection: CalendarSelectionStorage {
    var ids: Set<String> = ["qa-calendar"]
    func load() -> Set<String> { ids }
    func save(_ ids: Set<String>) { self.ids = ids }
}
@MainActor final class QALogin: LoginItemBackend, LoginItemInitializationStore {
    var hasInitializedLoginItem = true
    var state: LoginItemState = .disabled
    func currentState() throws -> LoginItemState { state }
    func register() throws { state = .enabled }
    func unregister() throws { state = .disabled }
}
final class VolatileReminderStorage: ReminderStorage, @unchecked Sendable {
    private let lock = NSLock()
    private var value = ReminderSettings()
    func load() throws -> ReminderSettings { lock.lock(); defer { lock.unlock() }; return value }
    func save(_ value: ReminderSettings) throws { lock.lock(); defer { lock.unlock() }; self.value = value }
}
actor QANotifications: ReminderNotificationBackend {
    private var requests: [ReminderRequest] = []
    private var permitted = false
    func permission() async -> ReminderPermission { .init(authorizationRawValue: permitted ? 2 : 0, alertRawValue: permitted ? 2 : 0) }
    func requestPermission() async throws { permitted = true }
    func pending() async -> [ReminderRequest] { requests }
    func add(_ request: ReminderRequest) async throws { requests.removeAll { $0.id == request.id }; requests.append(request) }
    func remove(_ identifiers: [String]) async { requests.removeAll { identifiers.contains($0.id) } }
    func deliveredIdentifiers() async -> [String] { [] }
}
