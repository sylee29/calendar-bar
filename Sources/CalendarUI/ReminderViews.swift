import SwiftUI
import AppKit
import CalendarCore
import CalendarNotifications

extension ReminderDeliveryState {
    var label: String {
        switch self {
        case .updating: return String(localized: "Checking schedule")
        case .scheduled: return String(localized: "Scheduled")
        case .partial: return String(localized: "Partly scheduled · rest needs checking")
        case .permissionRequired: return String(localized: "Notification or calendar permission needed")
        case .failed: return String(localized: "Scheduling failed · please try again")
        case .needsConfirmation: return String(localized: "Event change needs confirmation")
        case .noFuture: return String(localized: "No future reminders scheduled")
        }
    }
}
@MainActor struct ReminderStatusView: View {
    let snapshot: ReminderDeliverySnapshot
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(snapshot.desiredEnabled ? String(localized: "Reminders on") : String(localized: "Reminders off")).font(.caption)
            Text(snapshot.state.label).font(.caption).foregroundStyle(.secondary)
            Text("\(snapshot.scheduled) scheduled · \(snapshot.deferred) deferred").font(.caption).foregroundStyle(.secondary)
        }.accessibilityElement(children: .combine)
    }
}
@MainActor struct ReminderEditorView: View {
    @Bindable var model: CalendarModel
    let reminders: ReminderCoordinator
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Button("Close") { model.cancelReminder() }
                    Spacer()
                    Text("Event Reminder").font(.headline)
                }
                if let event = model.selectedReminderEvent, let draft = model.reminderDraft, model.canDisplayReminder {
                    Text(event.title).font(.headline)
                    Text(event.isAllDay ? model.localized(event.start, "MMMd") + " · " + String(localized: "All day") : model.localized(event.start, "MMMdHHmm")).font(.caption).foregroundStyle(.secondary)
                    ReminderStatusView(snapshot: reminders.snapshot(for: event))
                    Divider()
                    if event.isRecurring {
                        Picker("Apply to", selection: Binding(get: { model.reminderDraft?.scope ?? .thisOccurrence }, set: { model.reminderDraft?.scope = $0 })) {
                            Text("This event only").tag(ReminderScope.thisOccurrence)
                            Text("This and future events").tag(ReminderScope.thisAndFuture).disabled(!draft.canUseFuture)
                        }
                        if !draft.canUseFuture { Text("Can't apply to future events because the recurring series couldn't be confirmed.").font(.caption).foregroundStyle(.secondary) }
                        if draft.occurrenceAnchor == nil { Text("Can't determine the original occurrence. Refresh the calendar and try again.").font(.caption).foregroundStyle(.red) }
                    }
                    if draft.requiresFormatConfirmation {
                        Text("The event changed between timed and all-day. Review the times for the new format.").font(.caption)
                        Toggle("Confirm changed event format", isOn: Binding(get: { model.reminderDraft?.formatConfirmed ?? false }, set: { model.reminderDraft?.formatConfirmed = $0 }))
                    }
                    TriggerFields(rows: Binding(get: { model.reminderDraft?.rows ?? [] }, set: { model.reminderDraft?.rows = $0 }), format: draft.format)
                    Button("Apply Default Times") { model.reminderDraft?.apply(reminders.settings.defaults) }
                    Text("Copies the default times. Later changes to the defaults won't apply to this event.").font(.caption).foregroundStyle(.secondary)
                    if let error = model.reminderError { Text(error).font(.caption).foregroundStyle(.red) }
                    HStack {
                        Button("Turn Off Reminder") { Task { await model.saveReminder(enabled: false) } }
                        Spacer()
                        Button("Save") { Task { await model.saveReminder(enabled: true) } }.buttonStyle(.borderedProminent)
                    }.disabled(model.reminderBusy || draft.occurrenceAnchor == nil)
                    if event.isRecurring, let existing = draft.existing, existing.scope == .thisOccurrence {
                        Button("Clear Override · Follow Series") { Task { await model.resumeInheritedReminder() } }.disabled(model.reminderBusy)
                    }
                    ReminderPermissionView(reminders: reminders)
                    Button("Recheck Schedule") { Task { await reminders.retry() } }
                    Text("The event itself is never changed.").font(.caption).foregroundStyle(.secondary)
                }
            }.padding(20)
        }
    }
}
@MainActor struct TriggerFields: View {
    @Binding var rows: [ReminderTriggerDraft]
    let format: ReminderFormat
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach($rows) { $row in
                HStack(spacing: 5) {
                    if format == .timed {
                        TextField("0", text: $row.hours).accessibilityLabel("Reminder hours before").frame(width: 48)
                        Text("h")
                        TextField("10", text: $row.minute).accessibilityLabel("Reminder minutes before").frame(width: 42)
                        Text("min before")
                    } else {
                        TextField("1", text: $row.days).accessibilityLabel("Reminder days before").frame(width: 38)
                        Text("days before at")
                        TextField("21", text: $row.wallHour).accessibilityLabel("Reminder hour 0 to 23").frame(width: 32)
                        Text(":")
                        TextField("00", text: $row.minute).accessibilityLabel("Reminder minute 0 to 59").frame(width: 32)
                    }
                    Spacer(minLength: 0)
                    Button { rows.removeAll { $0.id == row.id } } label: { Image(systemName: "minus.circle") }.buttonStyle(.plain).accessibilityLabel("Delete this reminder time")
                }.textFieldStyle(.roundedBorder).font(.system(size: 12))
            }
            Button("Add Reminder Time") { rows.append(ReminderTriggerDraft(format == .timed ? try! .timed(hours: 0, minutes: 10) : try! .allDay(daysBefore: 1, hour: 21, minute: 0))) }
            Text(format == .timed ? String(localized: "At least 1 min before · minutes 0–59") : String(localized: "0 days before = same day · hour 0–23, minute 0–59 · current time zone")).font(.caption).foregroundStyle(.secondary)
        }
    }
}
@MainActor struct ReminderPermissionView: View {
    let reminders: ReminderCoordinator
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !reminders.permission.canSchedule {
                Text("Notifications must be allowed before reminders can be scheduled.").font(.caption)
                Button("Request Notification Permission") { Task { await reminders.requestPermission() } }
                Button("Notification Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") { NSWorkspace.shared.open(url) }
                }
            }
            if let error = reminders.permissionRequestError { Text(error).font(.caption).foregroundStyle(.red) }
            if let error = reminders.storageError { Text(error).font(.caption).foregroundStyle(.red) }
        }
    }
}
@MainActor struct ReminderSettingsView: View {
    let reminders: ReminderCoordinator
    @State private var timed: [ReminderTriggerDraft] = []
    @State private var allDay: [ReminderTriggerDraft] = []
    @State private var error: String?
    @State private var saved = false
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reminders").font(.headline)
            Text("\(reminders.scheduled) scheduled · \(reminders.deferred) deferred · \(reminders.needsConfirmation) need confirmation").font(.caption)
            if let date = reminders.lastScheduled { Text("Last checked: \(date.formatted(date: .abbreviated, time: .shortened))").font(.caption).foregroundStyle(.secondary) }
            else { Text("No reminders scheduled yet.").font(.caption).foregroundStyle(.secondary) }
            Button("Recheck Schedule") { Task { await reminders.retry() } }
            ReminderPermissionView(reminders: reminders)
            Toggle("Hide Reminder Title and Time", isOn: Binding(get: { reminders.settings.hideContent }, set: { value in
                Task { do { try await reminders.setHideContent(value); error = nil } catch { self.error = String(localized: "Couldn't save the reminder content setting.") } }
            })).toggleStyle(.checkbox)
            Text("Timed Event Defaults").font(.subheadline)
            TriggerFields(rows: $timed, format: .timed)
            Text("All-Day Event Defaults").font(.subheadline)
            TriggerFields(rows: $allDay, format: .allDay)
            Button("Save Default Times") {
                Task {
                    do {
                        try await reminders.updateDefaults(ReminderDefaults(timed: timed.map { try $0.trigger(format: .timed) }, allDay: allDay.map { try $0.trigger(format: .allDay) }))
                        error = nil; saved = true
                    } catch { self.error = String(localized: "Couldn't save default times. Enter at least one valid time for each format."); saved = false }
                }
            }
            if saved { Text("Default times saved · existing events are unchanged.").font(.caption).foregroundStyle(.secondary) }
            if let error { Text(error).font(.caption).foregroundStyle(.red) }
            Text("Turn on reminders for each event yourself. Up to 48 of the nearest reminders within the next year are scheduled; the rest are filled in while the app runs. If the app has been closed for a long time, open it again. Changes, deletions, and permission revocations made while the app is quit aren't reflected, so a reminder with an old title may remain.").font(.caption).foregroundStyle(.secondary)
        }
        .onAppear {
            timed = reminders.settings.defaults.timed.map(ReminderTriggerDraft.init)
            allDay = reminders.settings.defaults.allDay.map(ReminderTriggerDraft.init)
        }
    }
}
