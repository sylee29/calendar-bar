# MenuBar

Owns the menu bar icon, popover, and login item.

Distinguish the popover lifecycle from the app lifecycle. Distinguish the record of the first automatic registration attempt from the system's actual state. Content is injected and retained.

Does not own calendar queries, event lists, or the date navigation model.

Test with an injected login backend and store. Unit tests never change real system settings. Check outside clicks and Escape on the real screen.
