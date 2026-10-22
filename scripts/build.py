#!/usr/bin/env python3
"""Build a locally signed macOS application bundle."""
import pathlib, plistlib, shutil, subprocess
root = pathlib.Path(__file__).resolve().parents[1]
def run(*args):
    subprocess.run(["python3", str(root / "scripts/run.py"), "300", *args], cwd=root, check=True)
run("swift", "build", "-c", "release", "--jobs", "2")
bindir = subprocess.check_output(["swift", "build", "-c", "release", "--show-bin-path"], cwd=root, text=True, timeout=30).strip()
app = root / "build/CalendarBar.app"
macos = app / "Contents/MacOS"
macos.mkdir(parents=True, exist_ok=True)
shutil.copy2(pathlib.Path(bindir) / "CalendarBar", macos / "CalendarBar")
(app / "Contents/Resources").mkdir(exist_ok=True)
shutil.copy2(root / "Resources/AppIcon.icns", app / "Contents/Resources/AppIcon.icns")
for lproj in ("en.lproj", "ko.lproj"):
    shutil.copytree(root / "Resources" / lproj, app / "Contents/Resources" / lproj, dirs_exist_ok=True)
info = {
    "CFBundleExecutable": "CalendarBar", "CFBundleIdentifier": "local.ian.CalendarBar",
    "CFBundleName": "CalendarBar", "CFBundleDisplayName": "Calendar Bar",
    "CFBundlePackageType": "APPL", "CFBundleIconFile": "AppIcon", "CFBundleVersion": "1", "CFBundleShortVersionString": "1.0",
    "CFBundleDevelopmentRegion": "en", "CFBundleLocalizations": ["en", "ko"],
    "LSMinimumSystemVersion": "14.0", "LSUIElement": True,
    "NSHighResolutionCapable": True,
    "NSCalendarsFullAccessUsageDescription": "Reads and shows events from the calendars you select. It never adds or changes events.",
    "NSCalendarsUsageDescription": "Reads and shows events from the calendars you select."
}
with (app / "Contents/Info.plist").open("wb") as out:
    plistlib.dump(info, out)
run("codesign", "--force", "--sign", "-", str(app))
run("codesign", "--verify", "--strict", str(app))
print(app)
