"""All tunables in one place. Edit values directly — no presets, no overrides.

Force values are 0–255 (DualSense raw). Frequencies are Hz.
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass
class Settings:
    # --- UDP ---
    udp_host: str = "0.0.0.0"
    udp_port: int = 5300
    udp_timeout: float = 0.5

    # --- Input deadzones (Forza Data Out pedal bytes 0-255) ---
    accel_deadzone: int = 10
    brake_deadzone: int = 10
    pedal_value_max: int = 255
    pedal_full_force_at: int = 248  # ~98%; jumps straight to force 255

    # --- Brake (left trigger): exponential ramp baseline -> full press ---
    # Baseline is ALWAYS held (no off()) so the trigger never "machine-guns"
    # by toggling rigid<->off around the deadzone.
    # Normal ramp max stays below 255; above 98% brake uses force 255.
    brake_baseline_force: int = 1  # constant weight when not pressed
    brake_max_force: int = 25      # normal ramp max below 100% input
    brake_curve: float = 2.5        # >1 = soft early, sharp at the end
    handbrake_bonus: int = 25       # extra rigid when handbrake engaged

    # --- ABS feel from tire slip telemetry (left trigger) ---
    enable_abs: bool = True
    abs_brake_threshold: int = 80
    abs_min_speed_kmh: float = 15.0
    abs_slip_ratio_threshold: float = 1.0
    abs_combined_slip_threshold: float = 1.0
    abs_freq: int = 35
    abs_amp: int = 255

    # --- Throttle (right trigger): exponential ramp baseline -> full press ---
    # Kept softer than the brake — a real gas pedal has very little resistance
    # compared to a brake pedal, and we need finger-travel budget free for the
    # gear-shift / rev-limit vibration animations.
    # Above 98% throttle uses force 255 inside the same ramp logic.
    throttle_baseline_force: int = 1
    throttle_max_force: int = 10    # softer than brake on purpose
    throttle_curve: float = 5.2     # steeper = even softer at light press

    # --- Rev limiter buzz (right trigger) ---
    rev_limit_ratio: float = 0.95   # rpm / max_rpm above this = limiter
    rev_limit_freq: int = 30
    rev_limit_amp: int = 255

    # --- Gear shift thump (right trigger, single vibration burst) ---
    enable_gear_shift: bool = True
    gear_shift_freq: int = 20           # short, noticeable thump
    gear_shift_amp: int = 255
    gear_shift_duration_ms: float = 100.0

    # --- Misc ---
    startup_pulse_force: int = 150
