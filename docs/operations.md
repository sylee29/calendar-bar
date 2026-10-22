# Build and Use

The verification environment is macOS 26.3.1 on Apple Silicon with Xcode installed and Swift 6.3.3. The package's minimum target is macOS 14; it has not been verified on older hardware/OS. No external packages need to be installed.

`python3 scripts/verify.py` runs tests, then a release build, bundles the executable and Info.plist into `build/CalendarBar.app`, and performs local ad-hoc signing and signature verification. It does not involve a paid developer account, notarization, or App Store distribution. The app icon is `Resources/AppIcon.icns`, copied into the bundle. When the design changes, regenerate it with `swift scripts/make_icon.swift <temp>/AppIcon.iconset` followed by `iconutil -c icns <temp>/AppIcon.iconset -o Resources/AppIcon.icns`. Normal launch is `open build/CalendarBar.app`. Login registration uses the app path, so if you move the bundle in use, recheck the launch-at-login state.

Turn on Google Calendar sync in macOS Internet Accounts and confirm events appear in Apple Calendar. After pressing "Connect Calendar" in the app, the user grants permission. Choose the calendars to display. Events edited in Google are reflected after macOS sync; immediate reflection is not guaranteed.

A time-limited run that does not touch auto-launch is `python3 scripts/run.py 120 build/CalendarBar.app/Contents/MacOS/CalendarBar --smoke --show`. This is not launch-at-login verification. Confirm process exit when the test ends. Real launch at login is recorded separately as normal-mode registration state and the user's re-login confirmation.


## Synthetic Events and Reminder Runs

First build the normal app with `python3 scripts/verify.py`. With no existing QA app running and no `build/CalendarBarQA.app`, run `python3 scripts/prepare_qa.py`. It copies the normal bundle, distinguishes it with display name Calendar Bar QA and identifier `local.ian.CalendarBar.qa`, and ad-hoc signs it again. The Applications install in actual use is not replaced.

`python3 scripts/run_qa.py 300 build/CalendarBarQA.app --qa --qa-window --qa-notifications --qa-seed "$(python3 -c 'import time; print(int(time.time()) + 180)')"` opens the separate QA app via LaunchServices and after 5 minutes cleans up only processes at that path. After exit, confirm `QA_PROCESS_ABSENT`. If the menu-only window is inaccessible, `--qa-window` shows the same view component in a regular window. Distinguish rendering checks in this window from checks of the real menu popover.

QA's reminder opt-in and synthetic base time are stored in `~/Library/Application Support/local.ian.CalendarBar.qa/qa-launch.json`, and reminder settings in `qa-reminders.json` in the same directory. The `.qa` identifier uses these settings and synthetic data even when relaunched without arguments, and does not register a login item. A plain `--smoke` does not schedule real reminders.

For OS verification, allow QA's notification permission, save two times on a near synthetic event, and check the scheduled count. Fully quit the QA app before the trigger, then check the arriving reminder and the cold-click target date. Second, click while the app shows a different date to check warm navigation. Do not create or modify personal source events. After the check, turn off the QA rules, check app-owned scheduled/delivered state, and restore QA notification permission if it was off before the test.

If the permission request ends in an error, read the registration/permission state of that QA entry in System Settings. Do not change other apps or global mirroring/sharing notification policies. Successful code signature verification and actual notification permission/delivery success are separate. Do not assume another helper executable using the same bundle ID has the same notification query permission as the original app.

Passing `--qa-notification-report` to the original CalendarBar executable in the `.qa` bundle prints its own request identifiers, scheduled/delivered times, and permission values as JSON within 10 seconds and exits. Example: `python3 scripts/run.py 15 build/CalendarBarQA.app/Contents/MacOS/CalendarBar --qa-notification-report`. No separate probe executable is added. A normal bundle returns `qa_bundle_required`, and this path does not query events, save settings, or add/cancel reminders. Title, body, and userInfo are not printed.
