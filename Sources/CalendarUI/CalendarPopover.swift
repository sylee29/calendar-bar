import AppKit
import SwiftUI
import CalendarCore
import CalendarAccess
import CalendarNotifications
import MenuBar
import ServiceManagement

@MainActor struct CalendarPopover: View {
    @Bindable var model: CalendarModel
    @ObservedObject var login: LoginItemController
    @State private var paging = MonthPagingState()
    @GestureState private var isDragging = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let pageWidth = 340.0
    var loginToggleBinding: Binding<Bool> {
        Binding(get: { login.state == .enabled }, set: { login.setEnabled($0) })
    }
    func cancelPendingLoginRegistration() { login.setEnabled(false) }
    var body: some View {
        VStack(spacing: 0) {
            if model.isResolvingReminder {
                VStack(spacing: 12) { ProgressView(); Text("Checking events…").font(.caption) }.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            else if model.canDisplayReminder, let reminders = model.reminders { ReminderEditorView(model: model, reminders: reminders) }
            else if model.showingSettings { settings } else {
                searchHeader
                if let message = model.navigationMessage {
                    Text(message).font(.caption).foregroundStyle(.secondary).padding(.horizontal, 16).padding(.bottom, 8)
                }
                if model.isSearching { searchPage }
                else if model.tab == .upcoming { upcomingPage }
                else { calendarPage }
            }
        }
        .frame(width: 340, height: 600)
        .background(Color(nsColor: .windowBackgroundColor))
        .onDisappear { resetPaging() }
        .onChange(of: model.access.permission) { _, _ in model.clearInaccessibleEditor() }
        .onChange(of: model.access.calendars) { _, _ in model.clearInaccessibleEditor() }
        .onChange(of: model.access.selectedCalendarIDs) { _, _ in model.clearInaccessibleEditor() }
        .onChange(of: model.presentationID) { _, _ in resetPaging() }
        .onChange(of: model.calendar.displayedMonth) { _, _ in resetPaging() }
    }
    private var calendarPage: some View {
        VStack(spacing: 0) {
            HStack(spacing: 13) {
                Text(model.localized(model.calendar.displayedMonth, "yMMMM"))
                    .font(.system(size: 18, weight: .semibold)).accessibilityAddTraits(.isHeader)
                Spacer()
                Button("Today") { model.open() }.font(.system(size: 11)).buttonStyle(.bordered)
                Button { settleMonth(-1) } label: { Image(systemName: "chevron.left") }
                    .accessibilityLabel("Previous month")
                Button { settleMonth(1) } label: { Image(systemName: "chevron.right") }
                    .accessibilityLabel("Next month")
            }.buttonStyle(.plain).padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 16)
            HStack(spacing: 0) {
                ForEach(Array(model.weekdaySymbols.enumerated()), id: \.offset) { index, day in
                    Text(day).font(.system(size: 11, weight: .medium))
                        .foregroundStyle(index == 0 ? .red.opacity(0.7) : .secondary)
                        .frame(maxWidth: .infinity)
                }
            }.padding(.horizontal, 16).padding(.bottom, 8)
            monthPager.padding(.bottom, 14)
            Divider().padding(.horizontal, 20)
            HStack {
                Text(model.localized(model.calendar.selectedDate, "MMMMdEEEE")).font(.system(size: 13, weight: .semibold))
                Spacer()
                if model.access.state == .loaded { Text(model.selectedEvents.count == 1 ? String(localized: "1 event") : String(localized: "\(model.selectedEvents.count) events")).foregroundStyle(.secondary).font(.system(size: 11)) }
            }.padding(.horizontal, 20).padding(.top, 15).padding(.bottom, 10)
            agenda.frame(maxHeight: .infinity)
            Divider()
            HStack {
                Button { model.showingSettings = true; login.refresh() } label: { Image(systemName: "gearshape").font(.system(size: 14)) }
                    .buttonStyle(.plain).foregroundStyle(.secondary).accessibilityLabel("Settings")
                Spacer()
            }.padding(.horizontal, 20).padding(.vertical, 12)
        }
    }
    private func pageState(_ amount: Int) -> CalendarState {
        var state = model.calendar
        if amount != 0 { state.moveMonth(by: amount) }
        return state
    }
    private func gridHeight(_ state: CalendarState) -> Double {
        Double(state.grid.days.count / 7) * 41 - 3
    }
    private var monthPager: some View {
        let currentHeight = gridHeight(model.calendar)
        let neighborHeight = gridHeight(pageState(paging.offset < 0 ? 1 : -1))
        let progress = min(1, abs(paging.offset) / pageWidth)
        return ZStack(alignment: .topLeading) {
            ForEach(-1...1, id: \.self) { amount in
                MonthGridPage(state: pageState(amount), events: model.access.events, onSelect: model.select)
                    .equatable()
                    .frame(width: pageWidth)
                    .offset(x: Double(amount) * pageWidth + paging.offset)
                    .allowsHitTesting(amount == 0 && !paging.isSettling)
                    .accessibilityHidden(amount != 0)
            }
        }
        .frame(width: pageWidth, height: currentHeight + (neighborHeight - currentHeight) * progress, alignment: .topLeading)
        .clipped()
        .contentShape(Rectangle())
        .highPriorityGesture(DragGesture(minimumDistance: 8)
            .updating($isDragging) { _, active, _ in active = true }
            .onChanged { value in
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    paging.drag(x: value.translation.width, y: value.translation.height, width: pageWidth)
                }
            }
            .onEnded { value in
                settleMonth(MonthSwipe.direction(x: value.translation.width, y: value.translation.height))
            })
        .onChange(of: isDragging) { _, active in
            if !active && !paging.isSettling && paging.offset != 0 { settleMonth(nil) }
        }
    }
    private func settleMonth(_ direction: Int?) {
        guard !paging.isSettling else { return }
        let presentation = model.presentationID
        var token: Int?
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.24), completionCriteria: .removed) {
            token = paging.settle(direction: direction, width: pageWidth)
        } completion: {
            guard presentation == model.presentationID, let token else { return }
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                guard paging.finish(token) else { return }
                if let direction { model.moveMonth(direction) }
            }
        }
    }
    private func resetPaging() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { paging.reset() }
    }
    @ViewBuilder private var agenda: some View {
        switch model.access.state {
        case .loaded:
            if model.selectedEvents.isEmpty {
                VStack { Spacer(); Text("No events").font(.system(size: 13)).foregroundStyle(.secondary); Spacer() }
            } else {
                ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(model.selectedEvents) { event in
                            EventDisplayRow(event: event, time: model.timeLabel(event), highlighted: model.highlightedEventID == event.id, action: nil, reminder: { model.editReminder(event) }, delivery: model.reminders?.snapshot(for: event)).id(event.id)
                        }
                    }.padding(.horizontal, 20).padding(.bottom, 12)
                }
                .onAppear { if let id = model.highlightedEventID { proxy.scrollTo(id, anchor: .center) } }
                .onChange(of: model.highlightedEventID) { _, id in if let id { proxy.scrollTo(id, anchor: .center) } }
                }
            }
        case .loading: ProgressView().controlSize(.small).frame(maxWidth: .infinity, maxHeight: .infinity)
        default: accessMessage.padding(.horizontal, 20)
        }
    }
    private var accessMessage: some View { stateMessage(model.access.state, retry: model.refresh) }
    @ViewBuilder private func stateMessage(_ state: CalendarViewState, retry: @escaping () -> Void) -> some View {
        VStack(spacing: 8) {
            switch state {
            case .connectionRequired:
                if model.access.permission == .denied || model.access.permission == .restricted {
                    Text("Calendar access isn't allowed.")
                    Button("Open System Settings") { openSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") }
                } else {
                    Text("Connect your calendars to see events.")
                    Text("macOS asks for full access.\nThis app only reads events.").font(.system(size: 10)).foregroundStyle(.secondary)
                    Button("Connect Calendar") { Task { await model.access.requestAccess() } }
                }
            case .noCalendars:
                Text("No calendars connected.")
                Text("Add Google or another account in Internet Accounts\nand turn on calendar sync.").font(.system(size: 10)).foregroundStyle(.secondary)
                Button("Open Internet Accounts") { openSettings("x-apple.systempreferences:com.apple.preferences.internetaccounts") }
            case .selectionRequired:
                Text("Select calendars to show.")
                Button("Select Calendars") { model.showingSettings = true }
            case .failed:
                Text("Couldn't load calendars.")
                Button("Try Again", action: retry)
            default: EmptyView()
            }
        }.font(.system(size: 12)).multilineTextAlignment(.center).frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    private var searchHeader: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search events", text: $model.searchText).textFieldStyle(.plain).accessibilityLabel("Search events")
                if !model.searchText.isEmpty {
                    Button { model.searchText = "" } label: { Image(systemName: "xmark.circle.fill") }
                        .buttonStyle(.plain).accessibilityLabel("Clear search")
                }
            }.padding(8).background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 6))
            Picker("View", selection: Binding(get: { model.tab }, set: { model.setTab($0) })) {
                ForEach(CalendarTab.allCases, id: \.self) { Text($0.title).tag($0) }
            }.pickerStyle(.segmented)
        }.padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 8)
    }
    private var searchPage: some View {
        VStack(alignment: .leading, spacing: 10) {
            DatePicker("Start", selection: $model.searchStart, displayedComponents: .date)
            DatePicker("End", selection: $model.searchEnd, displayedComponents: .date)
            if model.searchInterval == nil {
                Text("End date must be after the start date.").font(.caption).foregroundStyle(.red)
                Spacer()
            } else {
                Text(verbatim: "\(model.localized(model.searchStart, "yMMdd")) – \(model.localized(model.searchEnd, "yMMdd")) · \(model.searchState == .loaded ? String(localized: "\(model.searchResults.count) results") : String(localized: "Searching"))")
                    .font(.caption).foregroundStyle(.secondary)
                Divider()
                if model.searchState == .loaded {
                    if model.searchResults.isEmpty { emptyMessage("No results") }
                    else {
                        ScrollView {
                            LazyVStack(spacing: 14) {
                                ForEach(model.searchResults) { event in
                                    EventDisplayRow(event: event, time: resultTime(event), highlighted: false,
                                        action: { Task { await model.activate(event, interval: model.searchInterval) } },
                                        reminder: { model.editReminder(event) }, delivery: model.reminders?.snapshot(for: event))
                                }
                            }.padding(.vertical, 5)
                        }
                    }
                } else if model.searchState == .loading { loading }
                else { stateMessage(model.searchState, retry: model.scheduleSearch) }
            }
        }.padding(.horizontal, 16).padding(.bottom, 16)
    }
    private var upcomingPage: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(verbatim: "\(model.localized(model.agendaInterval.start, "MMMd")) – \(model.localized(model.agendaInterval.end.addingTimeInterval(-1), "MMMd"))")
                .font(.caption).foregroundStyle(.secondary)
            Divider()
            if model.agendaState == .loaded {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        if model.agendaGroups.isEmpty { Text("No upcoming events").foregroundStyle(.secondary) }
                        ForEach(model.agendaGroups) { group in
                            Text(model.localized(group.day, "MMMMdEEEE")).font(.system(size: 13, weight: .semibold)).accessibilityAddTraits(.isHeader)
                            ForEach(group.events.map { AgendaDisplayRow(day: group.day, event: $0) }) { row in
                                let event = row.event
                                EventDisplayRow(event: event, time: agendaTime(event, day: group.day), highlighted: false,
                                    action: { Task { await model.activate(event, interval: model.agendaInterval) } },
                                    reminder: { model.editReminder(event) }, delivery: model.reminders?.snapshot(for: event))
                            }
                            Divider()
                        }
                        Button("Show 30 More Days") { model.loadMoreAgenda() }.frame(maxWidth: .infinity)
                    }.padding(.vertical, 5)
                }
            } else if model.agendaState == .loading { loading }
            else { stateMessage(model.agendaState, retry: model.refreshAgenda) }
        }.padding(16)
    }
    private var loading: some View { ProgressView().controlSize(.small).frame(maxWidth: .infinity, maxHeight: .infinity) }
    private func emptyMessage(_ message: LocalizedStringKey) -> some View { Text(message).font(.system(size: 13)).foregroundStyle(.secondary).frame(maxWidth: .infinity, maxHeight: .infinity) }
    private func resultTime(_ event: EventOccurrence) -> String {
        model.localized(event.start, "Md") + " " + (event.isAllDay ? String(localized: "All day") : model.formatted(event.start, "HH:mm"))
    }
    private func agendaTime(_ event: EventOccurrence, day: Date) -> String {
        if event.isAllDay { return event.start < day ? String(localized: "All day · In progress") : String(localized: "All day") }
        return event.start < day ? String(localized: "In progress") : model.formatted(event.start, "HH:mm")
    }
    private var settings: some View {
        ScrollView {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button { model.showingSettings = false } label: { Label("Back", systemImage: "chevron.left") }.buttonStyle(.plain)
                Spacer()
                Text("Settings").font(.headline)
            }
            Divider()
            Text("Calendars to Show").font(.system(size: 12, weight: .semibold))
            if model.access.calendars.isEmpty { accessMessage.frame(height: 150) }
            else {
                Group {
                    VStack(spacing: 12) {
                        ForEach(model.access.calendars) { item in
                            Toggle(isOn: Binding(get: { model.access.selectedCalendarIDs.contains(item.id) }, set: { enabled in
                                Task {
                                    var ids = model.access.selectedCalendarIDs
                                    if enabled { ids.insert(item.id) } else { ids.remove(item.id) }
                                    await model.access.setSelectedCalendarIDs(ids)
                                }
                            })) {
                                HStack(spacing: 8) {
                                    Circle().fill(Color(item.color)).frame(width: 7, height: 7)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.name).font(.system(size: 12))
                                        Text(item.sourceName).font(.system(size: 10)).foregroundStyle(.secondary)
                                    }
                                }
                            }.toggleStyle(.checkbox)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            Divider()
            if let reminders = model.reminders { ReminderSettingsView(reminders: reminders); Divider() }
            Toggle("Launch at Login", isOn: loginToggleBinding).toggleStyle(.switch).font(.system(size: 12))
            if login.state == .requiresApproval {
                Text("Approve the login item in System Settings.").font(.caption).foregroundStyle(.secondary)
                Button("Login Items Settings") { SMAppService.openSystemSettingsLoginItems() }
                Button("Cancel Registration", action: cancelPendingLoginRegistration)
            }
            if case .failure(let message) = login.state {
                Text(message).font(.caption).foregroundStyle(.secondary)
                Button("Check Again") { login.refresh() }
            }
            Spacer(minLength: 0)
            Divider()
            Button("Quit Calendar Bar") { NSApplication.shared.terminate(nil) }.buttonStyle(.plain).font(.system(size: 12)).foregroundStyle(.secondary)
        }.padding(20)
        }
    }
    private func openSettings(_ url: String) { if let url = URL(string: url) { NSWorkspace.shared.open(url) } }
}
extension Color {
    init(_ color: RGBAColor) { self.init(.sRGB, red: color.red, green: color.green, blue: color.blue, opacity: color.alpha) }
}

/// Lazy stacks flatten nested ForEach children; an occurrence shown on multiple
/// days needs a presentation identity distinct from its underlying event identity.
struct AgendaDisplayRow: Identifiable {
    struct ID: Hashable {
        let day: Date
        let event: EventOccurrence.ID
    }
    let day: Date
    let event: EventOccurrence
    var id: ID { ID(day: day, event: event.id) }
}

@MainActor private struct EventDisplayRow: View {
    let event: EventOccurrence
    let time: String
    let highlighted: Bool
    let action: (() -> Void)?
    let reminder: () -> Void
    let delivery: ReminderDeliverySnapshot?
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if let action { Button(action: action) { content }.buttonStyle(.plain) }
            else { content }
            Button(action: reminder) {
                Image(systemName: delivery?.scheduled ?? 0 > 0 ? "bell.fill" : delivery?.desiredEnabled == true ? "bell.badge" : "bell")
                    .foregroundStyle(delivery?.scheduled ?? 0 > 0 ? Color.accentColor : .secondary)
            }
                .buttonStyle(.plain).accessibilityLabel(Text("Reminder settings: \(event.title), \(delivery?.state.label ?? String(localized: "Reminders off"))"))
                .help(delivery.map { String(localized: "\($0.state.label) · \($0.scheduled) scheduled · \($0.deferred) deferred") } ?? String(localized: "Reminders off"))
        }.padding(4).background(highlighted ? Color.accentColor.opacity(0.12) : .clear, in: RoundedRectangle(cornerRadius: 4))
    }
    private var content: some View {
        HStack(alignment: .top, spacing: 8) {
            RoundedRectangle(cornerRadius: 2).fill(Color(event.color)).frame(width: 3, height: 29)
            Text(time).font(.system(size: 11)).foregroundStyle(.secondary).frame(width: 66, alignment: .leading)
            VStack(alignment: .leading, spacing: 3) {
                Text(event.title).font(.system(size: 12, weight: .medium)).fixedSize(horizontal: false, vertical: true)
                Text(event.calendarName).font(.system(size: 10)).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }.contentShape(Rectangle()).frame(maxWidth: .infinity, alignment: .leading)
    }
}
