# CalendarUI

Owns the calendar, event, and settings screens and user input.

Use Core dates as the basis for the screen. Don't handle a drag and a date click twice, and don't attach the month-change gesture to list scrolling. Distinguish connection failures from no events.

Does not own direct EventKit object access, event editing, or process entry.

Automatically test month-end navigation, gesture boundaries, and the continuous navigation model, and check real 4/5/6-week screens and clicks/drags.

A search result's body navigates to the current occurrence's start date, and the bell button opens a standalone editor. A reminder click takes precedence over the reset-to-today of a normal reopen. Distinguish configured intent from actually scheduled, deferred, permission required, and partial failure. Verify default-time copying and recurring per-event exceptions in the UI model; system notification APIs go through the notifications module. QA injects a synthetic backend into the real screen components, and the regular smoke run doesn't schedule OS notifications.

Recurring reminder drafts distinguish the anchors of per-event edits and future-events edits, and future-events boundaries follow the existing series representation. If the occurrence identity under the storage rules is ambiguous, don't create a savable anchor. Clearing a per-event override uses the stored exception's identity and anchor and does not recompute from the current display form.
