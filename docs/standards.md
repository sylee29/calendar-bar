# Change and Verification Standards

Respect Swift Package module boundaries. CalendarCore owns only Foundation calculations, CalendarAccess owns CalendarCore and the system event API, CalendarNotifications owns CalendarCore·CalendarAccess and the system notification API, MenuBar owns the menu bar and login items, CalendarUI owns these four modules, and CalendarBar owns only app entry. Do not put UI or EventKit objects in Core.

The event query API exposes only reads. EventKit objects are not passed outside the actor; they are converted to values. UI-published state changes on the main actor, and stale async responses are never adopted as the current result. Introduce a new external dependency only with evidence that platform built-ins cannot solve the problem.

`python3 scripts/verify.py` runs all tests and the release app build and signature verification. After code changes, confirm this command exits 0. Date/permission/async boundary changes include tests that verify the real boundary. UI behavior changes are checked in the real app, and passing with mock data is not reported as real-account integration success.

Verify processes with runs that have time limits and exit handling, such as `scripts/run.py`. Do not log out or reboot arbitrarily in the name of verification. Do not push or publish without user approval. Check Git changes before working and do not revert other workers' files.

Separate channels and request generations so search, Upcoming, and reminder queries do not overwrite each other's results. Do not show scheduling success from notification permission or save success alone; match against system pending requests. Never treat a failure as event deletion or use a title as a recurring-event identifier. Real reminder verification is done with synthetic events in a separate QA bundle, and a normal smoke run does not change OS notifications.
