# System Integration Contracts

There is no external HTTP API. Only EventKit fullAccess is treated as permission to read events. notDetermined is not yet requested, denied/writeOnly is the connection-refused state, and restricted is the restricted state. Insufficient permission is never converted into a successful 0-result response.

Queries take a start-inclusive, end-exclusive date range for each channel (calendar grid, search, Upcoming, reminders) and the set of selected calendar IDs. An empty selection never queries all calendars. Calendars carry system ID, name, source, and color; events carry calendar ID, event ID, occurrence start, end, title, and all-day flag. Recurring occurrences with the same event ID are not merged.

View states are distinguished as needs connection, no calendars, needs selection, loading, query success, and query failure. Success includes 0 results. On EventKit change notifications and wake from sleep, the store is re-read and old objects are not reused. System sync delay is a contract outside the app.

ServiceManagement's enabled, notRegistered, requiresApproval, and notFound are shown as on, off, needs approval, and failed, respectively. Having sent a registration request alone is not shown as on.

UserNotifications receives deterministic request IDs with an app-specific prefix, trigger time, display content, and an internal link token. Both the OS's scheduling permission and banner permission are checked, and actual scheduling is determined by re-querying pending requests. Save errors, permission needed, partial scheduling, and needs confirmation are distinguished from success. Cancellation is limited to requests this app owns, and normal quit is not a cancellation request.

The token in a system notification response is the input for finding the stored event identity link. The target date is opened only after revalidating current selection, permission, and the original occurrence basis. Gone, outside selection, insufficient permission, ambiguous, and query failure are each handled, and personal events are never shown from an old title or payload date alone. A recurring occurrence outside the query range does not mean deletion.
