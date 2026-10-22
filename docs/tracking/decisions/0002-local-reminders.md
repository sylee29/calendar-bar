# Local Reminders That Survive App Quit

Event management continues in the existing calendar, but the user needs multiple reminders for only the occurrences they choose. Reminders already set must be delivered even while the menu bar app is quit.

The app reads current events and pre-schedules near reminders in UserNotifications. No separate resident helper, server, or changes to source event alerts are used. A resident helper could improve change detection but needs its own process lifecycle, permissions, and distribution; a server adds transmission of personal events and account management. Editing source alerts changes the boundary of a read-only tool.

Therefore, when the app is fully closed, pre-scheduled reminders are delivered, but changes, deletions, and permission revocation that happen afterward cannot be reflected immediately. The user accepted the limitation that an old title may remain. Scheduling fills the limit starting with the nearest reminders and replenishes while running, and the next launch rechecks current permission, selection, and events. After a long period quit, the app must be relaunched.
