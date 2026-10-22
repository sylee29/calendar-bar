# CalendarNotifications

Owns local reminder settings and scheduling, cancelling, and recovering system notifications.

Never modify source events. Use only CalendarCore values and CalendarAccess read results. Do not store titles or account information in its own settings or logs.

Distinguish configured intent from actual scheduled state. Remove related reminders when permission revocation or deselection is confirmed, and keep scheduled reminders on normal app quit. Don't let stale async work revive cancelled reminders.

Verify recurring exceptions, multiple reminders, failure recovery, and concurrent changes with an injected clock, store, and scheduling backend. Unit tests never send or delete real user notifications.

Don't infer deletion from a query failure alone. Cleanup for turn-off, hiding, permission loss, and corrupted settings runs independently of query failures. When the current occurrence can't be confirmed, don't cancel the whole series; quarantine only the risky occurrences. Recheck both pending and delivered requests, and reconcile the actual scheduled count against the OS response. External changes during a normal quit aren't detected; clean them up on the next launch.

Verify recurring exceptions, occurrences moved far away, per-event form changes, settings save failures, schedule add failures, changes while hiding, stale responses, and timer reset and teardown with an injected backend. OS verification uses only the separate QA bundle.

Recurring scheduling and state reconciliation use the same kind of original occurrence basis as the storage rules. An ambiguous civil basis is never accepted as a safe schedule, and fallback bases used for lookup are not added to stored settings. Keep the identity links of existing version 1 settings.
