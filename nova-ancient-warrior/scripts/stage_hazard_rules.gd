extends RefCounted
## Deterministic, readable arena hazards. Call from the player's physics tick.

const SPIKE_PULSE_PERIOD := 3.8
const SPIKE_WARNING_SECONDS := 0.8
const SPIKE_ACTIVE_END := 1.65
const LAVA_CHANNEL_X := [-6.72, -4.48, -2.24, 2.24, 4.48, 6.72]
const LAVA_PULSE_PERIOD := 4.6
const LAVA_WARNING_SECONDS := 0.9
const LAVA_ACTIVE_END := 2.0
const THRONE_RUNE_X := [-4.0, -2.0, 2.0, 4.0]
const THRONE_PULSE_PERIOD := 5.2
const THRONE_WARNING_SECONDS := 1.15
const THRONE_ACTIVE_END := 2.05


static func query(stage_index: int, position: Vector3, elapsed: float) -> Dictionary:
	match clampi(stage_index, 0, 2):
		0:
			var in_spike_lane := absf(position.z - 8.4) <= 0.55 and absf(position.x) <= 6.0
			var pulse := fposmod(maxf(0.0, elapsed), SPIKE_PULSE_PERIOD)
			var warning := in_spike_lane and pulse < SPIKE_WARNING_SECONDS
			var active := in_spike_lane and pulse >= SPIKE_WARNING_SECONDS and pulse < SPIKE_ACTIVE_END
			return {
				"warning": warning,
				"active": active,
				"damage": 10,
				"label": "SUNKEN SPIKE TRAP" if in_spike_lane else ""
			}
		1:
			var on_lava := absf(position.z) <= 10.5
			var in_lava_channel := false
			if on_lava:
				for channel_x in LAVA_CHANNEL_X:
					if absf(position.x - float(channel_x)) <= 0.48:
						in_lava_channel = true
						break
			var pulse := fposmod(maxf(0.0, elapsed), LAVA_PULSE_PERIOD)
			var warning := in_lava_channel and pulse < LAVA_WARNING_SECONDS
			var active := in_lava_channel and pulse >= LAVA_WARNING_SECONDS and pulse < LAVA_ACTIVE_END
			return {
				"warning": warning,
				"active": active,
				"damage": 10,
				"label": "LAVA CHANNEL" if in_lava_channel else ""
			}
		_:
			var pulse := fposmod(maxf(0.0, elapsed), THRONE_PULSE_PERIOD)
			var in_rune_lane := absf(position.z + 1.5) <= 8.0
			var over_rune := false
			if in_rune_lane:
				for rune_x in THRONE_RUNE_X:
					if absf(position.x - float(rune_x)) <= 0.34:
						over_rune = true
						break
			var warning := over_rune and pulse < THRONE_WARNING_SECONDS
			var active := over_rune and pulse >= THRONE_WARNING_SECONDS and pulse < THRONE_ACTIVE_END
			return {
				"warning": warning,
				"active": active,
				"damage": 14,
				"label": "OBSIDIAN RUNES"
			}
