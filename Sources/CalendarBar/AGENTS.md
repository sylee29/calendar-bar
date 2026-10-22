# CalendarBar

Owns app entry and delegate lifecycle wiring.

Start on the main actor and retain the delegate and coordinator while running. Do not quit when the popover closes.

Date calculation, EventKit queries, and screen layout are outside this module's scope.

Distinguish a normal bundle launch from --smoke --show. After entry point changes, confirm the actual launch callbacks and the menu bar.

Connect the notification delegate before the app runs, and deliver a cold-launch response after the UI is ready. Navigate from a notification token only after rechecking the current event. A no-argument launch of the `.qa` identifier must still keep synthetic data, isolated storage, and no login registration.

`--qa-notification-report` runs read-only and only in `.qa`, branching before delegate setup, settings creation, and schedule reconciliation. It prints only OS permissions, its own request identifiers, and times, and never reads or prints personal titles, bodies, or userInfo. If the regular app receives a diagnostic argument, it refuses without starting the real app.
