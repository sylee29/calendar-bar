# Date and Event Rules

Today and the selected date are distinct. Today is the current date in the system time zone; the selected date is the basis of the event list. Opening the popover or pressing the "Today" button brings both to today. A midnight or time zone change alone does not reset the date being browsed.

The Gregorian monthly grid shows complete weeks from Sunday to Saturday. Adjacent-month dates are shown, and selecting one moves to that month. Month navigation keeps the selected date's day of month and clamps nonexistent dates to the last day of the month. 1/31→2/28→3/28. The original 31st is not hidden and restored.

Dragging left goes to the next month, right to the previous month, and each release moves only one month. Horizontal movement must exceed vertical movement and be over 40pt. During a drag the previous, current, and next months follow the pointer; on release the move finishes over 0.24 seconds. A short drag snaps back. The selected month and event query change only after the transition finishes, and duplicate input during a transition is ignored. Vertical list scrolling is not month navigation. With Reduce Motion enabled, the transition animation is skipped.

Days with events in the selected calendars show a colored dot per calendar. Different calendars are distinct even with the same name. Events are start-inclusive and end-exclusive; an event ending at midnight does not extend into the next day. A zero-length event belongs only to its start date. Each occurrence of a recurring event is distinct.

Sort all-day events first, then by start time, title, and identifier. A timed event that started on a previous day shows "In progress"; a multi-day all-day event shows "All day · In progress". A missing title shows "(No title)". Only a successful query with 0 results shows "No events"; insufficient permission, no selection, and failure are each shown separately.

Clicking outside the window closes only the popover. Quitting the app is a separate explicit action. Once the user turns off launch at login, it is not automatically turned back on at the next launch.

## Search and Upcoming

Search applies only to titles in the selected calendars, with a default range of one year before and after today. Start and end dates are editable, and the end date's full day is included. An invalid range, 0 search results, and a query failure are distinct states. Clicking a result's body moves to the month and date containing that occurrence's current start date and scrolls to and highlights that row. The bell button opens reminder editing, separate from date navigation.

Upcoming shows 30 days by date starting from the whole of today, so it includes events already past today. Multi-day events appear on each date they span. "Show 30 more days" extends by 30 days at a time, and vertical scrolling is not interpreted as month navigation. A normal menu open returns to today and the default range and clears search. When opened from a reminder, the reminder's target date takes precedence.

## App Reminders

A reminder is scheduled only after the user turns it on for each event. Defaults are 60 and 10 minutes before for timed events and 21:00 the day before for all-day events, and can be changed. Applying defaults copies them into the event being edited; later changes do not apply retroactively to existing events. Multiple times can be added and removed, and duplicates are merged. Timed events use positive minute offsets; all-day events use days before and a local time. Reminder times already past are not scheduled.

Recurring events apply to "This event only" or "This and future events". Changing the future rule keeps explicit per-event overrides, and "clear override" makes the occurrence follow the recurring rule again. Recurrence relationships are not inferred from identical titles. If an occurrence cannot be safely identified, only that occurrence's unsafe schedules are canceled and confirmation is requested; safe schedules for other occurrences are preserved.

A recurring occurrence's original time and original local date are kept as identity evidence independent of the current timed/all-day display format. If a stored date basis overlaps multiple occurrences of the same series, it stays "needs confirmation" and no reminder is saved on an ambiguous basis. A future rule in the same series continues the existing boundary's time/date representation and never mixes incomparable boundaries. Clear override targets the stored per-event rule rather than building a new basis from the view's current format.

Timed events subtract the offset from the absolute start instant. All-day events subtract days from the local date and apply the wall-clock time. A time skipped by DST uses the next valid time; a repeated time uses the first occurrence. A change between all-day and timed format does not reinterpret old settings without user confirmation.

Within a one-year forward query range, up to 48 nearest reminders are scheduled first and the rest are deferred. The limit can be adjusted in the implementation. A distant individual event can be rechecked directly to schedule it. Rebalancing happens while the app runs, and the scheduled count, deferred count, and last scheduling check are shown. Enabled in settings differs from actually scheduled.

Pre-scheduled reminders remain after the app quits. Event changes, deletions, and permission revocation while the app is quit are not reflected until the next launch, so a reminder with an old title may appear. They are cleaned up when checked at the next launch. When a reminder is clicked, the app does not trust the past payload alone and rechecks current permission, selection, and event identity. Editing the source event's alerts, server/mobile push, a separate resident process, and snooze are not provided.
