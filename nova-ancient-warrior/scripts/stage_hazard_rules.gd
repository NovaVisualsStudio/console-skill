extends RefCounted
## Deterministic, readable arena hazards. Call from the player's physics tick.

const LAVA_CHANNEL_X := [-6.72, -4.48, -2.24, 2.24, 4.48, 6.72]
const THRONE_RUNE_X := [-4.0, -2.0, 2.0, 4.0]
const THRONE_PULSE_PERIOD := 5.2
const THRONE_WARNING_SECONDS := 1.15
const THRONE_ACTIVE_END := 2.05


static func query(stage_index: int, position: Vector3, elapsed: float) -> Dictionary:
	match clampi(stage_index, 0, 2):
		0:
			var in_spike_lane := absf(position.z - 8.4) <= 0.55 and absf(position.x) <= 6.0
			return {
				"warning": false,
				"active": in_spike_lane,
				"damage": 10,
				"label": "SUNKEN SPIKE TRAP"
			}
		1:
			var on_lava := absf(position.z) <= 10.5
			if on_lava:
				for channel_x in LAVA_CHANNEL_X:
					if absf(position.x - float(channel_x)) <= 0.48:
						return {
							"warning": false,
							"active": true,
							"damage": 10,
							"label": "LAVA CHANNEL"
						}
			return {"warning": false, "active": false, "damage": 0, "label": ""}
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
