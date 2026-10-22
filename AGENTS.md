# Calendar Bar

A native Swift menu bar app for checking today's date and whether there are events, on a personal Mac.
Events are managed in Google Calendar; this app reads the selected calendars synced to macOS.

## Project structure

```text
.
├── AGENTS.md                         → work entry point
├── CLAUDE.md                         → same working rules
├── docs/
│   ├── architecture.md               → components and data flow
│   ├── business-rules.md             → date, selection, and event rules
│   ├── security.md                   → permission and privacy boundaries
│   ├── standards.md                  → change and verification standards
│   ├── engineering-notes.md          → implementation caveats confirmed in practice
│   ├── operations.md                 → build, run, and connection procedures
│   ├── contracts.md                  → macOS integration contracts
│   ├── verification.md               → verification run and unverified scope
│   └── tracking/
│       ├── status.md                 → implementation status and remaining checks
│       ├── findings.md               → unresolved problems
│       └── decisions/
│           ├── index.md              → decision list
│           ├── 0001-system-calendar.md → why we read the system calendar
│           └── 0002-local-reminders.md → trade-off between reminders while quit and refresh
└── Sources/
    ├── CalendarBar/AGENTS.md          → app entry and lifecycle wiring
    ├── CalendarCore/AGENTS.md         → date and event calculations
    ├── CalendarAccess/AGENTS.md        → system event queries
    ├── CalendarNotifications/AGENTS.md → app reminder scheduling and recovery
    ├── MenuBar/AGENTS.md               → popover and login item
    └── CalendarUI/AGENTS.md            → screens and gestures
```

## Core standards

- The app only reads events. Do not add APIs that save, edit, or delete events.
- Do not record secrets or personal event content in code, logs, or verification materials.
- Before reporting success, check tests and real behavior appropriate to the change, and call out what is unverified.
- Put time limits on long-running processes and confirm verification processes have exited.

## Before starting work

Read `docs/standards.md`, `docs/engineering-notes.md`, and the relevant module's `AGENTS.md`.
Before date or gesture changes, check `docs/business-rules.md`; before permission or storage changes, `docs/security.md` and `docs/contracts.md`; before app placement or launch-at-login changes, `docs/operations.md`.

Report immediately to the user any call that writes to events, exposure of personal events after permission revocation, or leaked secrets. Record other unresolved problems in `docs/tracking/findings.md` with reproduction conditions and why they remain unresolved.
