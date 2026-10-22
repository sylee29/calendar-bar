# CalendarAccess

Owns system permissions, calendar queries, and persisting the calendar selection.

Keep EventKit objects inside an actor. Store only the selected IDs, and never turn an empty selection into a query of all calendars. Check the request generation and permission before publishing results.

Does not own event writes, UI layout, or the login item.

Verify stale responses, permission revocation, disappearing calendars, failures, and zero results with a controllable fake backend. Automated tests never make requests against real accounts.

The ranges and results of the Calendar, search, Upcoming, and reminder channels are independent. Check that a global invalidation doesn't leave another pending channel loading forever or publish an old response. Direct occurrence lookups apply the same permission and selection boundaries as range queries. Distinguish out-of-range, deleted, failed, and ambiguous, and never link a series by title.

Pass EventKit's original occurrence time as two values: instant and civil date. Don't drop the other representation based only on the current all-day flag. Check uniqueness of the date basis across whole days at the query boundary, then clamp actual results back to the requested range. A date collision within the same series is needsConfirmation; never pick one ambiguous match arbitrarily.
