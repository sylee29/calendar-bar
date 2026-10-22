# Permissions and Privacy

The user's system calendars and account information are protected. Google authentication and token storage, refresh, and revocation are handled by macOS account settings. The app itself does not collect passwords or authentication tokens.

| Actor | Condition | Allowed | Forbidden |
|---|---|---|---|
| App | Full event access granted and calendars selected | Read selected events | Write events or calendars |
| App | Not requested, denied, restricted, or write-only permission | Date calendar and connection guidance | Show personal events |
| User | App settings | Change displayed calendars and launch at login | Edit events through the app |

Do not describe the system permission named full access as a read-only permission. Only the app's behavior is limited to reading. After a permission change, recheck permission right before publishing query results and remove previous content whose permission was lost.

The app stores selected IDs, whether initial login registration was attempted, and reminders' identifiers, occurrence basis, triggers, defaults, and content-hiding setting. Reminder settings are replaced atomically and titles are not stored. Menu bar position is stored separately by AppKit. Raw event content, titles, account addresses, and credentials are never written to logs or docs. There is no analytics SDK and no external transmission. Verification records contain only commands, exit codes, and non-identifying pass/fail. Permission request success, state changes, and failures are conveyed as UI state, and no separate personal activity audit log is created.

OS reminders include the event title and time by default. Turning on content hiding replaces them with generic text and also cleans up already delivered reminders. When the app detects permission revocation or deselection while running, it removes related pending and delivered reminders. While the app is fully quit it cannot detect this, so an old title may remain; the user accepted this limitation. A read failure is not evidence of deletion, but explicit intents such as turning off or hiding apply even during query failures. If the settings file is corrupted and ownership mapping cannot be trusted, the file is preserved and app-owned reminders are cleaned up. Other apps' notifications are never touched.

Real reminder QA uses only the `.qa` bundle identifier, synthetic events, and an independent store. Even if a reminder click causes an argument-less relaunch, it does not access system events or login items. Verification query output includes only app-owned request identifiers, scheduled times, and status.
