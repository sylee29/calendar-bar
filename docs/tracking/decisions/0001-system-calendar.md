# Reading Through the System Calendar

## Context

The user only checks dates and whether events exist, and keeps adding and editing events in Google Calendar. A personal tool should not need its own authentication management.

## Decision

Read events from accounts registered on the Mac via EventKit and display only the calendars the user selects. Only settings are stored locally.

## Alternatives and Consequences

Signing into Google directly in the app is independent of the Mac's accounts but adds authentication setup and token management. The user chose the system account approach. Therefore the app does not connect a Google account on its own, and system calendar sync is required. Server changes made before sync cannot be fetched immediately by this app.
