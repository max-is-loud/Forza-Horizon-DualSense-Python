"""System tab: global / launch-time settings, with the ZUV update toggle at
the top.

The ZUV loader runs *before* this app starts, so toggling the update check here
only affects the next launch. The mechanism is a sentinel file
(.zuv-update-disabled) the loader checks in its cache_root; when present, the
update check is skipped. ZUV exports cache_root via the ZUV_CACHE_ROOT env var.
"""
import logging
import os
from pathlib import Path

from textual.app import ComposeResult
from textual.containers import Horizontal
from textual.widgets import Label, Switch

from lang import t

from .settings_tab import SYSTEM_SECTIONS, SettingsTab

log = logging.getLogger("fhds")

SENTINEL = ".zuv-update-disabled"


def sentinel_path() -> Path | None:
    """Path to the sentinel file, or None when not running inside a ZUV bundle."""
    root = os.environ.get("ZUV_CACHE_ROOT")
    return Path(root) / SENTINEL if root else None


def apply_sentinel(enabled: bool) -> None:
    """Reconcile the on-disk sentinel with the desired setting.
    enabled=True  -> updates wanted -> remove sentinel.
    enabled=False -> updates off    -> create sentinel.
    No-op when running outside a ZUV bundle (no ZUV_CACHE_ROOT)."""
    path = sentinel_path()
    if path is None:
        return
    try:
        if enabled:
            path.unlink(missing_ok=True)
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.touch(exist_ok=True)
    except OSError as e:
        log.warning("Could not update %s: %s", SENTINEL, e)


class SystemTab(SettingsTab):
    SECTIONS = SYSTEM_SECTIONS
    SHOW_RESET = False

    def compose(self) -> ComposeResult:
        # Update toggle lives at the top of the System tab (no longer a tab of
        # its own). The sentinel only works inside a ZUV bundle.
        yield Label(t("Updates"), classes="section")
        if sentinel_path() is None:
            yield Label(
                t("ZUV not found: this build is not running inside a ZUV bundle "
                  "(ZUV_CACHE_ROOT env var is missing), so the update toggle has "
                  "nothing to control. Run the bundled .zuv.py to manage updates."),
                classes="error",
            )
        else:
            with Horizontal(classes="row"):
                yield Switch(value=self.settings.check_for_updates, id="check_for_updates")
                yield Label(t("Check for updates at launch"))
            yield Label(
                t("When off, ZUV will not prompt for updates on startup. "
                  "Toggle on and restart the app to check for a new release."),
                classes="hint",
            )
        yield from super().compose()

    def on_mount(self) -> None:
        # Reconcile sentinel with stored setting in case the cache was wiped or
        # the prefs file was edited externally.
        if sentinel_path() is not None:
            apply_sentinel(self.settings.check_for_updates)

    def on_switch_changed(self, event: Switch.Changed):
        super().on_switch_changed(event)
        if event.switch.id == "check_for_updates":
            apply_sentinel(event.value)
