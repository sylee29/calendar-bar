# Verification Record

## Automated Verification

2026-09-28, macOS 26.3.1 / Apple Silicon / Swift 6.3.3.

- `python3 scripts/verify.py`: exit 0. Internal `swift test --jobs 2` passed 32 tests, `python3 scripts/build.py` exit 0. Release app bundle build and `codesign --verify --strict` succeeded.
- 8 date model tests, 13 menu bar date/login state/anchor tests, 6 event access tests, 5 view state/gesture calculation tests.
- Before implementation, tests were confirmed failing (exit 1) because the types did not exist, then implemented. The fake backend does not change user events or login items.

## Found and Fixed

- Grid calculation in `Sources/CalendarCore/CalendarState.swift`: querying America/Asuncion 2023-10 propagated 01:00 into dates, so the query covered the first hour of the day after the last day. Fixed by normalizing each date to start of day, with the regression test confirmed failing→passing.
- Empty title in `Sources/CalendarCore/EventOccurrence.swift`: the display missing parentheses was fixed to the spec's "(No title)" and the test was confirmed passing.
- Initialization in `Sources/CalendarBar/main.swift`: directly initializing the main-actor delegate at the Swift Package entry point made the integrated build exit 1. After fixing with an explicit main actor context and retaining the delegate, full verification exit 0.

## Real Runs and Limits

- Confirmed a time-limited `CalendarBar --smoke --show` process run and the app start callback. A stack sample showed waiting in the NSApplication event loop. This is not evidence that the UI works correctly.
- The computer-use tool's access by app bundle ID/absolute path failed with `timeoutReached`. Finder accessibility queries worked, but screen captures were white. After correcting menu bar display permission, the real UI verification below was done.
- Real permission grant, calendar selection, and event queries on the first build were confirmed below. Permission on the final rebuild, sync of external service changes, and re-login are checked separately.
- Initially the auto login item was verified only with a fake backend. Real registration and enabled state were later confirmed, and re-login was not performed. No logout or reboot was done in the name of verification.

## Additional Findings and Fixes

- There was no path to cancel registration of auto-launch in the awaiting-approval state. Instead of falsely showing on, a "Cancel Registration" button was added.
- Progress state of multi-day all-day events was not shown. Added the "All day · In progress" display and a regression test.
- The today color followed the system accent color. Fixed to a constant blue.
- Next-midnight calculation also had the Asuncion 01:00 propagation problem. Normalized to the start of the next day.
- In time-limited runs, only the parent was terminated and grandchild processes ignoring SIGTERM could remain. Added group-level cleanup. `python3 -B -m unittest discover -s scripts -p test_run.py`: 3 real-process scenarios exit 0, also included in the full verification command.
- User checks revealed the popover appearing at the bottom-left and failing to close on outside click. Blocked showing at an anchor without a screen and added closing on outside/in-app clicks and app deactivation. Icon-anchored position and dragging were then confirmed for real, and outside-click closing was confirmed by the user.

## Real Connection Check

In a normal app bundle run, after granting event permission, the system's Google default calendar was selected. On 2026-09-29, 2 real events with time and title display, and date dots, were confirmed in the UI. Personal titles and account addresses are not included in this record. This was a check on a previous build; the final UI check and relaunch records below add permission restoration and drag results.

## Final UI Behavior Check

After allowing menu bar display, a capture confirmed the real popover's arrow attaches at the top. A check that it does not open at screenless coordinates was also tested. Confirmed in the real UI: left drag 9/28→10/28, right drag back to 9/28, and month/selected date unchanged on a 24pt short drag. Confirmed window access timeout after Escape and return to today on explicit reopen. Automation tools can retain accessibility content of a closed popover, so the mere presence of a text tree is not judged as an open state.

The count, titles, and times of 9/29 events in the same Google calendar in Apple Calendar were compared read-only and matched the app's earlier query. Nothing was written to the calendar source. After this record, permission and selection restoration were confirmed on a relaunch of the same install. Outside-click closing was later confirmed by the user as working correctly.

## Relaunch and Auto-Launch Check

After quitting the same install with the app's quit button and reopening it, calendar access and selection were retained and it returned to the successful 0-result state. Display of 2 Google events on 9/29 and 1 all-day event on 9/17 was read in the final UI. The 6-week layout of August 2026 was captured to confirm the last week and the event area are visible together.

After turning on the Launch at login switch in the real install, the system-queried state changed to enabled. Found a code path that skipped initial registration while treating the initial notFound state as a failure display, and fixed the first launch to attempt registration in states other than enabled/awaiting approval. Regression test failing→passing confirmed. Real logout/re-login was not performed.

## Fix Locations at Initial Implementation

| Problem found | Location as initially recorded (may have moved since) |
|---|---|
| Month grid with skipped midnight | `Sources/CalendarCore/CalendarState.swift:23` |
| Empty title parentheses | `Sources/CalendarCore/EventOccurrence.swift:42` |
| App entry main actor | `Sources/CalendarBar/main.swift:26` |
| Cancel registration awaiting approval | `Sources/CalendarUI/CalendarPopover.swift:174` |
| Distinguishing continuing all-day events | `Sources/CalendarUI/CalendarModel.swift:56` |
| Constant blue for today | `Sources/CalendarUI/CalendarPopover.swift:77` |
| Next midnight correction | `Sources/MenuBar/StatusDate.swift:10` |
| Child process cleanup | `scripts/run.py:38` |
| Screenless popover anchor | `Sources/MenuBar/MenuBarController.swift:81` |
| Closing on outside click/deactivation | `Sources/MenuBar/MenuBarController.swift:91` |
| Registration from initial notFound state | `Sources/MenuBar/LoginItemController.swift:78` |

Additional check after granting permission on the final install: the user completed the system grant, and the app was confirmed to read the 2 events on 2026-09-29 in the Google default calendar again. The awaiting-permission state is now resolved. Outside-click closing was also later confirmed by the user.

2026-09-28 final user confirmation: answering the outside-click closing question, the user confirmed it works correctly and requested a README introduction, usage, and how-it-works write-up and public publishing on GitHub.

## Smooth Month Transition Fix

- Cause: the existing gesture in `CalendarPopover` changed only the month value in `onEnded`, so there was no position feedback during the drag and no transition animation.
- Fix: added drag state and previous/current/next pages in `Sources/CalendarUI/MonthPaging.swift`, and move/snap-back animations in `CalendarPopover`. The actual month and query range change only after the transition ends. Reopening invalidates previous callbacks, and unnecessary recalculation of date and event dots for the same page is suppressed.
- `python3 scripts/verify.py`: exit 0. 35 Swift tests, 3 process cleanup tests, release build and signature verification passed.
- New regression tests check drag position tracking, one-page move limit, input lock during transitions, duplicate completion prevention, short-drag snap-back, and stale callback invalidation. They failed to compile before implementation due to undefined types and passed after. These automated tests alone are not claimed to measure visual smoothness.
- The install was replaced. Direct drag verification could not be completed due to screen automation's `noWindowsAvailable`; the user operated the install and confirmed correct behavior.


## Search, Upcoming, and App Reminder Verification

2026-09-28, the Swift native QA bundle was separated with an identifier different from the real install. Nothing was written to system calendar sources, and real account events, titles, and addresses were not used in this verification.

| Command | Exit result | Scope confirmed |
|---|---|---|
| `python3 scripts/verify.py` | 0 | 99 Swift, 5 Python, release bundle and ad-hoc signature verification |
| `python3 -B -m unittest discover -s scripts -p test_run.py` before implementation | 1 | 2 new group-check tests failed, 3 existing real child-process tests held |
| Same Python command after implementation | 0 | Error kept when real group exists after EPERM, absence confirmed, grandchild cleanup on success/failure/timeout |
| `python3 scripts/prepare_qa.py` | 0 | Separate `.qa` bundle copied and signed |
| `python3 scripts/run_qa.py 2 build/CalendarBarQA.app --smoke --qa-window` | 124 | `QA_PROCESS_ABSENT` after time limit expiry; run that does not write OS notifications |

In a separate 1-second time-limited run of `/bin/sleep` in `run.py`, EPERM on the group check after exit was reproduced. After a fix that independently confirms group absence via `ps`, the real descendant termination test passed. Test failures were not interpreted as OS notifications or app crashes.

### Confirmed on the Real Screen

- Title search default range 2025-09-28–2027-09-28; shrinking the end date to 2026-09-28 excludes the 10/15 result; a start date after the end date is an error; a nonexistent query shows the 0-result message. Before selecting the second synthetic calendar its title has 0 results, and 1 after selection.
- Clicking the fixed synthetic search result moves to October 2026 with the 15th selected, and that row's background is highlighted. Clearing search returns to the calendar, and the view segment switch works. Failure states and exclusion of non-title fields are the scope confirmed by fake-backend automated tests.
- The Upcoming range extends from 9/28–10/27 to 11/26 with "Show 30 more days". Vertical scrolling keeps the Upcoming view. Found a real bug where multi-day events vanished as empty rows on the next date, fixed it with date+occurrence identifiers at `Sources/CalendarUI/CalendarPopover.swift:246`, and confirmed via AX and screen that rows and bell buttons appear on both 9/28 and 9/29.
- Checked the regular QA window and the real menu popover opened from Finder separately. 4-week grid for 2026-02, 5-week for 2026-09, and 6-week for 2026-08 render together with the event area. Confirmed full AX content of a long title and the bell button.
- Confirmed timed reminder 2-minute and 1-minute input, adding and removing times, saving default 10→15 minutes while existing 2 and 1 minutes are kept, and copying 60 and 15 minutes after applying default times. For all-day, saved two times: 21:00 the day before and 09:30 the same day. Confirmed the recurring future rule, a 20-minute "This event only" override, restoration to 10 minutes after clear override, and turning off.
- Confirmed the content-hiding checkbox, permission request failure message, and distinction between enabled in settings and scheduled 0/permission-needed states. Failure, permission loss, deselection, query races, keeping recurring overrides, and corrupted settings cleanup are automated fake-backend verification and are not reported as tests that revoked real user permission.

### OS Reminder Observations and Remaining Items

Direct launch, LaunchServices, and Finder launch of the new identifier `local.ian.CalendarBar.runtime.qa` without helper executables all showed the initial permission request failure message. A separate helper probe returned UNErrorDomain 1 and an empty list, but OS logs rejected that probe's own request, so it was not used as evidence of the original app's empty list. The helper probe is not included in the final tooling. The cause of failure is not concluded from ad-hoc signing alone.

Read that Calendar Bar QA and Calendar Bar Runtime QA were each registered in System Settings with notification permission off. After turning on only the test Runtime QA entry, the real app's permission-needed message disappeared. Other apps and global sharing/mirroring notification policies were not changed. Saving two reminders changed the UI, based on re-querying system pending requests, to 2 scheduled and 0 deferred.

Synthetic base time Unix 1790572429, occurrence start 180 seconds later, reminder triggers 1790572489 and 1790572549. The QA process was terminated at Unix 1790572480.56688 before the first trigger, and its absence was confirmed in the process list. The original install PID 98965's executable path was unchanged. The Notification Center tool returned only the Weather widget window, so the banner and reminder click have not yet been observed directly. OS delivered-list checks and cold/warm click target date verification are not reported as complete.


2026-09-28 follow-up user confirmation: the user replied "I can see the alarm" (translated from Korean), confirming the real test reminder appeared on screen. This is the user's manual observation, not evidence that a tool captured the banner or confirmed it in the OS delivered list. It is not extended to confirming each of the two reminders' arrival, the reminder click, or the target date and row highlight for cold/warm launches. Whether the test calendar and that event row open after a click awaits the user's answer.

The `.qa`-only read command added to the original CalendarBar executable reads only OS state before starting the app delegate, event queries, settings writes, or schedule rebalancing. `python3 scripts/run.py 15 build/CalendarBarRuntimeReport.app/Contents/MacOS/CalendarBar --qa-notification-report`: exit 0, authorization=2, alert=2, pending=0, delivered=0. This copy has the same Runtime QA bundle ID but a different executable and code hash from the time of scheduling, which limits the equivalence of the result. An empty delivered list is not used to judge that the banner actually arrived. The existing bundle that is the user's click target was not replaced.

The read-only query `security find-identity -v -p codesigning` exit 0, valid identity count 0. This only describes the ad-hoc build environment and does not determine the cause of the initial permission request failure or a delivery failure. No paid account work, certificate creation, or global privacy settings changes were made.


### Preserved State While Awaiting the Initial Click (Historical Record)

The following records the time when the first manual user click confirmation was awaited, and is not the current preserved state or an instruction to halt work. Later state follows the last follow-up verification paragraph. At that time, `build/CalendarBarRuntimeQA.app` in the project root preserved the bundle as it was at scheduling. Runtime QA notification permission was on, and global sharing policy was not changed. The diagnostic `build/CalendarBarRuntimeReport.app` is a separate copy in the verification checkout and does not replace the original click target. Additional scheduling and GUI interaction were stopped.

Runtime QA's `~/Library/Application Support/local.ian.CalendarBar.runtime.qa/qa-launch.json` has notifications=true, synthetic base Unix 1790572429. `qa-reminders.json` retains 1 active rule for the near test event. The previous Calendar Bar QA identifier has opt-in=false and 0 active rules. These values are the app's settings intent and are not equivalent to OS pending/delivered state.

Our own QA process and report process were terminated. The watchdog checked its owned PID and working path and stopped in the app-absent state, so it will not belatedly kill an app the user opens via reminder click. In the final process check, only the existing `/Users/ian/Applications/CalendarBar.app/Contents/MacOS/CalendarBar` PID 98965 remained. After the real click is confirmed, QA reminders and rules will be cleaned up and QA notification permission restored to off as before the test. Feature completion, new install deployment, and push were not performed.


### Recurrence Format Change and Override Restoration Fix Verification

Additional regression tests confirmed: original instant and civil evidence independent of the current display format, needs confirmation and edit blocking for ambiguous date evidence, inheriting the boundary representation for future rules in the same series, and clearing overrides using the stored per-event identity and anchor. Only fallback evidence for lookup was added, and the reminder settings version 1 structure is kept.

`python3 scripts/verify.py` run in the fix-only checkout exited 0. `/tmp/calendar-format-restore-final-verify.log` showed 108 Swift, 3 existing Python cleanup tests, and release and signature verification passing. This comes from a different run than the earlier integrated checkout's 99 Swift and 5 Python results. Later on 2026-09-28, `python3 scripts/verify.py` was rerun from the project root and exited 0. In this single integrated run, 108 Swift, 5 Python cleanup tests, release build, and signature verification all passed. These are not summed numbers from different runs.

This update checked only doc references and diffs. Real test reminder display has user confirmation, and cold/warm clicks still await an answer. GUI interaction, QA reminder cleanup, and permission restoration were not performed.

### User Reminder Click Result

After confirming the test reminder appears, the user reported that clicking it just dismissed it and the calendar did not open. This result is not treated as a real click success. App absence before the test schedule and a new QA process launching after the click were confirmed, but the popover the computer-use tool later read may have been affected by the tool's activation. Click entry, view readiness, and date delivery will be diagnosed separately, and the real click rechecked after the fix.

After the reminder-click lifecycle fix, project-root `python3 scripts/verify.py` exited 0, with 113 Swift, 5 Python, release build, and signature verification passing. Tests wiring the real coordinator to the display driver confirmed readiness delay, deactivation, new reopen, target date, highlight, 2-second expiry, and normal reopen reset. Unit test success does not substitute for user click success. QA-only constant step diagnostics for the retest were added temporarily at that time, and their later removal is recorded below.


### Follow-Up Verification After the Popover-First Display Fix

An old QA diagnostic bundle with the same identifier was unregistered, backed up, and removed. The path that first waited for activation was fixed to show a valid popover first and then request activation. With Orca off, the real QA popover and showSucceeded were confirmed, but this is not evidence of reminder click success.

The preserved log `.dryforge/window-first-integrated-clean.log` was read directly during this doc update. For the 2026-09-28 18:01 run, it confirmed 116 Swift with 0 failures, 9 Python OK, and EXIT 0 for all three stages Swift/Python/build. The build stage includes release bundle and signature verification. The earlier 108/5 and 113/5 records are each past runs and are not summed. This log does not pin the run SHA, so it is not extended to verifying the current HEAD or the later diagnostics-removal change. The doc author read the preserved log, and the main verifier's later integrated run result is recorded separately below.

On resumption, the main verifier confirmed exit 0, authorization=2, alert=2, pending=0, delivered=1 from the report command of the same canonical QA executable. New step diagnostics showed only launch. One delivered-list entry and a process launch do not prove the real click callback, screen display, target date, or row highlight succeeded. Cold/warm click retests and cleanup verification on real OS reminder turn-off, content hiding, and permission revocation remain. The cause of the initial permission request failure, real-account recurring override combinations, and re-login/reboot persistence also remain unresolved/unverified.

Actual execution on the minimum supported macOS 14 is unverified. Running on macOS 26.3.1 or a successful minimum-target build does not guarantee behavior on older versions. After the test ends, cleaning up QA rules and pending/displayed reminders and restoring QA notification permission to its original off remain. The temporary step diagnostics' source and dedicated tests were removed in `185d998`. The existing canonical QA diagnostic build for the real click retest is preserved, distinguishing source removal from the state of the installed test bundle. After removing diagnostics, the main verifier ran full verification from the project root at `185d998`. The doc author directly confirmed in `.dryforge/resume-integrated-verify.log` the 2026-09-28 21:44 run with 114 Swift and 0 failures, 9 Python OK, EXIT 0 for all three stages, and INTEGRATED_EXIT 0. It includes release bundle and signature verification. The drop from 116 to 114 is due to removing 2 tests dedicated to temporary diagnostics. At the time of this integrated verification, real click success was unconfirmed, and the scope of later confirmation is recorded below.


### Cold Click Screen Display Confirmation and Warm Click Progress

In a follow-up cold click, the user confirmed that clicking the existing reminder opens the view. Before the main verifier's GUI interaction, step diagnostics for QA PID 41981 recorded launch → responseWithToken → routeBegin/showRequested → showFailed → routeHighlighted → waitingAnchor ×2 → showSucceeded → popoverDidShow. Display succeeded about 0.41 seconds after the request, and closeRequested was recorded about 4 seconds later. One canonical QA and the existing normal app PID 61441 remained. This is evidence of launch and screen display from a real OS click. routeHighlighted is model state, so it is not extended to confirming the target date and row highlight on the real screen.

The warm click retest was prepared with one reminder at 2026-09-28 21:56 KST. After saving a 20 hours 16 minutes before entry in the UI, the same executable's report showed pending=1, fire time 2026-09-28T21:56:00+09:00, delivered=0. The calendar was returned to today and closed with Escape while keeping the QA process. After 21:56 the same executable's report was exit 0, pending=0, delivered=1, but there was no new responseWithToken. At this point only the delivered list was confirmed, and the user click and cleanup verification were pending. Later results follow below.


### Warm Click Confirmation and Real Reminder Cleanup on Final Code

Asked to confirm navigation to September 29 and row highlight after the warm click, the user answered "Yep, confirmed" (translated from Korean). Before the main verifier's GUI reselection, the same QA PID 41981 recorded responseWithToken → routeBegin → showSucceeded → routeHighlighted → popoverDidShow, with no process relaunch. The warm click's date and highlight rest on both user observation and diagnostics. The earlier cold click confirmation covers user-observed screen display and step diagnostics, and is not extended to confirming the cold target date and highlight on the real screen.

After the click test, QA PID 41981 was terminated, and the 600-second watchdog session 64060 ended with exit 0, QA_PROCESS_ABSENT. The executable of canonical `build/CalendarBarRuntimeQA.app` was replaced with the final diagnostics-removed `build/CalendarBar.app` executable, and ad-hoc signing and signature verification exit 0 were confirmed. No other QA copies were created and the in-use install's files were not changed. Then the final code's real screen and OS schedule cleanup were verified with `scripts/run_qa.py`'s 600-second limit and the `--qa --qa-notifications --qa-window` options.

| Real action | UI and same-executable OS query result |
|---|---|
| Save timed reminder 20 hours 0 minutes before → turn reminder off | UI scheduled 1·pending/delivered 1/0 → UI 0·OS 0/0 |
| Save 20 hours 8 minutes before (22:04) and 19 hours before | OS 2/0 → after 22:04 1/1 |
| Turn content hiding on | OS 1/1 → 1/0: remaining schedule kept, displayed reminder removed |
| Deselect → reselect QA sample calendar | UI 0·OS 0/0 → UI 1·OS 1/0 |
| Turn off only Runtime QA notification permission in System Settings and recheck schedules in the app | UI permission needed·scheduled 0, authorization=1·alert=2·pending/delivered 0/0 |

Content hiding was restored to false, that rule was turned off, and QA launch notifications=false was saved. Stored active rule count 0 and hide=false were confirmed. The helper script for this check failed in two runs that assumed the settings structure, but after reading the `ReminderSettings` source, active rules 0 was confirmed by recursive counting. This is a failure of the check script and is not recorded as a product save failure.

QA did not quit with Cmd-Q, so SIGTERM was sent to the PID at the exact QA executable path. Time-limited run session 39609 ended with exit 0, QA_PROCESS_ABSENT, and the final read report confirmed OS pending/delivered 0/0. Test notification permission was restored to its original off. Source events, in-use install files, login items, and other apps' permissions were not changed.

This real permission test is a revocation of system notification permission. Because the synthetic calendar backend was used, real Calendar fullAccess revocation was not verified. The cause of the initial notification permission request error, real-account detached recurring override combinations, macOS 14 execution, and re-login/reboot persistence remain limitations. The source is the same as `185d998`, fully verified earlier, and the 114 Swift·9 Python·overall exit 0 record is used as evidence for the same source. This follow-up change is docs-only, so links, references, and diffs were checked, and it is not reported as a new full test run.


### Merge to main and In-Use Install Replacement

On 2026-09-28 the user approved merging to main and replacing the in-use app. origin/main's `1a65f57` README title edit was preserved and integrated into the feature branch without conflict, and landed on main as no-ff merge `1503248`. Product code is identical to `f0f7d79`, so the earlier same-source verification of 114 Swift·9 Python·overall exit 0 still holds. No remote push was performed.

The existing `/Users/ian/Applications/CalendarBar.app` was backed up to `.dryforge/backup/CalendarBar-before-reminders-20260928-221151.zip` with permissions 0600. The existing normal app PID 61441 was quit normally and replaced with the verified build, and internal SHA-256 equality true between built and installed executables and codesign verification exit 0 were confirmed. After launching with open in a clean environment, exactly one new normal app PID 66871 ran.

ControlCenter logs were checked for metadata in JSON filtered to PID 66871 only: tracking 1·displayableCreated 1·itemAdded 1·blocked 0, query exit 0. This is evidence of the new install's launch and menu registration, distinct from checking the personal event view or calendar permission retention. The personal event view was not queried. The previously stated limitations (real-account recurring overrides, real calendar permission revocation, the cause of the initial notification permission request, macOS 14, re-login, etc.) remain. This update documents the install result, and doc links and diffs were checked.

On 2026-09-29, after adding the app icon, full `python3 scripts/verify.py` exit 0 was confirmed. Rendering the built and installed bundles' icons with `NSWorkspace.icon(forFile:)` confirmed the new design resolves and macOS 26's gray plate overlay is absent. The install was replaced after quitting the existing PID 66871 normally; the executable and icon SHA-256 matched the build, codesign verification exit 0, exactly one relaunched PID 89114, and ControlCenter blocked 0 in the minute immediately after were confirmed. Actual icon display in reminder banners and login items, and the personal event view, were not checked.
