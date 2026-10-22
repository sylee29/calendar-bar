# CalendarCore

Owns the date grid, selection state, read-only event values, title search, per-date upcoming lists, and reminder rules.

Use Gregorian with an injected time zone. Month navigation clamps the current selected day to the month's last day. Normalize to the start of day after adding dates.

Does not reference UI, EventKit, or local settings.

Test leap years, year end, DST skipped midnight, recurring occurrences, zero length, and events ending at midnight.

Distinguish the reminder's occurrence basis from the current start date. Subtract time offsets from the absolute instant, and compute all-day bases by civil date. Test duplicate triggers, past reminders, nonexistent/repeated DST times, and recurring future-events rules with per-event exceptions. Does not own system scheduling or file storage.

Distinguish the original occurrence's instant and civil basis from the current display form. Leave date-basis collisions as needs confirmation, but give precedence to an exact per-event exception. A future-events rule inherits the existing anchor kind of the same series and rejects replacing a mixed boundary. Test timed↔all-day switches, multiple occurrences on the same date, and edits before the first boundary.
