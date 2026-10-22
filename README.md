# Calendar Bar

**English** | [한국어](README.ko.md)

**A small macOS calendar in the menu bar for finding events, viewing them together, and getting reminders.**
Click the icon to open a monthly calendar; click outside to close it. No main window or Dock icon.

## Features

- Today highlighted, with colored dots on days that have events
- Select a date to see event titles, times, and whether they are all-day
- Change months by dragging left/right or with the arrows
- Search event titles and jump straight to a result's date
- View upcoming events grouped by date in the **Upcoming** tab
- Set multiple reminders on events you choose, and change the default reminder times
- "This event only" and "This and future events" scopes for recurring events, plus reminders for all-day events
- Already-scheduled reminders are delivered even after the app quits; clicking a reminder opens that event
- Choose which calendars to show, and launch at login
- English and Korean UI, following your macOS system language

## Install and run

Requires macOS 14 or later, the Swift 6 toolchain (Xcode or Command Line Tools), and Python 3.
Actual runs were verified on macOS 26.3.1 on Apple Silicon; macOS 14 has not been verified on real hardware.

```sh
git clone https://github.com/seungyoon-lee29/calendar-bar.git
cd calendar-bar
python3 scripts/verify.py
open build/CalendarBar.app
```

The verify command runs the tests and builds the app together. Move the generated `build/CalendarBar.app` to the Applications folder and run it from there. If you use launch at login, keep the app in that location.

> The app is built with local signing; no notarized installer is provided. After a rebuild, the app may ask for calendar access again.

### Installing with Claude Code

If the commands are a hassle, open Claude Code in the cloned folder and ask:

```text
Build and run this app. Ask me before moving it to the Applications folder.
```

You need to approve the calendar and notification permission prompts yourself.

## First-time setup

> **Tip:** If you connect an account such as Google Calendar to the built-in Mac Calendar app, you can see events right from the menu bar without signing in to this app separately. Besides Google, iCloud, Exchange, and CalDAV accounts can also be selected if they appear in the built-in Calendar.

1. In **System Settings → Internet Accounts**, connect your Google account and turn on **Calendars** sync. Skip this step if your Google events already appear in the built-in Calendar app.
2. Click the date icon in the menu bar and choose **Connect Calendar**.
3. Allow access in the macOS permission prompt. The system requests **Full Access**, but this app only reads events.
4. In the gear **Settings**, choose the calendars to show. Simply leave out calendars you don't need, such as holiday calendars.

## Usage

| Action | How |
|---|---|
| Open/close | Click the menu bar icon. Close by clicking outside or pressing `Esc` |
| Read dates | The blue circle is today; a colored dot under a date means it has events |
| View events | Click a date to show its events below |
| Change month | Transitions smoothly following your hand. Left is next month, right is previous month. A short movement snaps back |
| Back to today | Click the **Today** button. Reopening from the menu bar icon resets to today and clears the search. Clicking a reminder goes to that event's date |
| Search events | Type part of a title in the search field at the top. Clicking a result's body jumps to its date and highlights the event |
| Overview | Check events by date in the **Upcoming** tab. **Show 30 More Days** adds the next period |
| Reminders | Use the bell button next to an event to set reminder times and scope, then **Save** |
| Launch at login | Toggle **Launch at Login** in Settings. If system approval is needed, follow the prompt to allow it |
| Quit | Choose **Quit Calendar Bar** in Settings |

When you change months, the selected day of the month is kept. If that day doesn't exist in the month, the last day is selected. For example, moving forward from January 31 selects the last day of February.

### Search and Upcoming

Search applies only to **event titles in the selected calendars**. The default search range is one year before and after today, and the start and end dates can be changed. It is a case-insensitive partial match; searching notes, locations, or Korean initial consonants (chosung) is not supported. The bell button in a search result opens reminder settings without changing the date.

Upcoming shows 30 days at a time starting today. It includes events that already ended today, and multi-day events appear on each date. Clicking the body of a search result or an Upcoming event jumps to the event's start date.

### Setting reminders

1. Click the **bell button** of the event you want in the Calendar, search results, or Upcoming.
2. For timed events, choose **how many hours/minutes before**; for all-day events, choose **how many days before and at what time**. Use **Add Reminder Time** to set several.
3. For recurring events, choose **This event only** or **This and future events**.
4. **Save**, allow notification permission, then check the **Scheduled** count and status. Reminder times that have already passed are skipped.

Reminders apply only to events you turn them on for. The initial defaults are **1 hour and 10 minutes before** for timed events and **9 PM the day before** for all-day events. You can change the defaults in Settings and copy them with **Apply Default Times** in the event editor. Changing the defaults doesn't change reminders on existing events.

A per-event override or turn-off on a recurring event is kept even if you change the future-events rule. You can revert it with **Clear Override · Follow Series**. **Turn Off Reminder** clears the scheduled and delivered reminders in that scope and doesn't change the source calendar's alert settings.

### When the app is quit

Reminders already scheduled with macOS are delivered even after the app quits. Clicking a reminder opens the app, rechecks the current event, and goes to its date.

- For recurring events, up to **48** of the nearest reminders within the next year are scheduled first, and the rest are topped up while the app is running. If the app stays quit for a long time, reminders beyond the scheduled range may not arrive.
- Event changes or deletions and calendar permission revocation while the app is quit aren't reflected until the next launch, so **reminders with the old title may remain**.
- Reminder sounds and banners are affected by macOS notification settings, Focus, sleep, and so on. Duplicates with alerts set in other calendar apps are not removed automatically.

## How does it work?

```text
Google Calendar → macOS calendar sync → read via EventKit → shown in the menu bar
```

The app doesn't sign in to Google directly; it reads **events from accounts connected to macOS**. So besides Google, you can select any calendar the system provides.

- Add, edit, and delete events in Google Calendar or the built-in Calendar app.
- Events are reread when the calendar opens, when the month or calendar selection changes, on system event changes, and on wake from sleep.
- Edits made in Google appear **after macOS syncs**. Immediate sync is not guaranteed.
- Reminders are scheduled as macOS local notifications. There is no separate server, no direct Google sign-in, and no analytics.
- The app stores the identifiers, times, and defaults needed for calendar selection and reminder linking; it does not store event titles, notes, or locations in its own files. **The macOS Notification Center may store titles and times.** Turning on **Hide Reminder Title and Time** in Settings switches to a generic message and also clears previously delivered reminders showing titles.

## If events or the icon don't appear

- **No events shown:** Check that the events exist in the built-in Calendar app, and check the app's access permission and selected calendars.
- **Permission denied:** Use the app's **Open System Settings** to allow calendar access. The date calendar works even without permission.
- **No reminders arrive:** Check that the event's reminder is on and check the **Scheduled** count. Allow notifications in **System Settings → Notifications → Calendar Bar** and check Focus too. If the permission request fails or no prompt appears, allow it directly in System Settings, then click **Recheck Schedule** in the app.
- **Event needs confirmation:** A change to the source event means the link couldn't be confirmed reliably. Refresh the calendar and recheck the current event's reminder settings.
- **No icon shown:** Check **System Settings → Menu Bar → Allow in the Menu Bar** in macOS. When run from a developer tool, it may be grouped under that tool's entry. Launching the app bundle from Finder is recommended.

Built with SwiftUI, AppKit, EventKit, UserNotifications, and ServiceManagement. Detailed verification results and unverified scope are in the [verification record](docs/verification.md).
