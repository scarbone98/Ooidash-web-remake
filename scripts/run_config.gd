class_name RunConfig
extends RefCounted

# All the tuning for a run lives here so difficulty can be adjusted in one place.

# Depth is measured in meters; Terry falls 1 m for every 100 px the hazards scroll.
const PIXELS_PER_METER := 100.0

const START_SPEED := 260.0
const SPEED_PER_METER := 0.22
const MAX_SPEED := 640.0

# Vertical distance between hazard rows. Grows a little with speed so the time
# between rows never drops much below ~0.6 s.
const BASE_ROW_GAP := 280.0
const ROW_GAP_PER_SPEED := 0.3

# Each zone adds a new kind of hazard. `double_chance` is how often a row blocks
# two lanes instead of one; `special_chance` is how often a row carries one of the
# zone's special hazards, picked by `specials` weight. `far_gap_chance` is how
# often the only gap sits two lanes from Terry (that row comes a little later so
# the double step is always possible). `boss` names the Boss that guards the zone.
const ZONES := [
	{
		"name": "Low Orbit",
		"depth": 0,
		"tint": Color(1, 1, 1),
		"double_chance": 0.2,
		"special_chance": 0.0,
		"specials": {},
		"far_gap_chance": 0.1,
	},
	{
		"name": "Comet Belt",
		"depth": 150,
		"tint": Color(0.55, 0.85, 1.0),
		"double_chance": 0.3,
		"special_chance": 0.3,
		"specials": {"comet": 1},
		"far_gap_chance": 0.15,
		"boss": "ufo",
	},
	{
		"name": "Haunted Void",
		"depth": 400,
		"tint": Color(0.75, 0.45, 1.0),
		"double_chance": 0.4,
		"special_chance": 0.4,
		"specials": {"comet": 1, "ghost": 2},
		"far_gap_chance": 0.2,
		"boss": "shadowbeast",
	},
	{
		"name": "Skull Storm",
		"depth": 750,
		"tint": Color(1.0, 0.6, 0.35),
		"double_chance": 0.5,
		"special_chance": 0.5,
		"specials": {"comet": 1, "ghost": 1, "skull": 2},
		"far_gap_chance": 0.25,
		"boss": "scarecrow",
	},
	{
		"name": "The Abyss",
		"depth": 1200,
		"tint": Color(1.0, 0.3, 0.3),
		"double_chance": 0.6,
		"special_chance": 0.6,
		"specials": {"comet": 1, "ghost": 1, "skull": 1},
		"far_gap_chance": 0.3,
		"boss": "swampthing",
	},
]

# Rows that put the gap two lanes away are spaced this much further apart.
const FAR_GAP_SPACING := 1.35

# Bosses: rows stop, the boss rises from below and attacks until its health
# (seconds of survival) runs out. Only surviving drains it; the katana doesn't.
const BOSS_ARRIVAL_DELAY := 2.0
const BOSS_BONUS := 100

const GEM_BONUS := 10
const SLICE_BONUS := 5

# Powers start showing up once Terry is past the first stretch.
const POWER_MIN_DEPTH := 40.0
const POWER_CHANCE_PER_ROW := 0.07
const POWER_COOLDOWN := 9.0
const POWER_WEIGHTS := {"shield": 3, "katana": 3, "slow": 2, "magnet": 2}
# Seconds of real time; the shield lasts until it absorbs a hit.
const POWER_DURATIONS := {"katana": 8.0, "slow": 5.0, "magnet": 10.0}
const SLOW_TIME_SCALE := 0.55

static func speed_at(depth: float) -> float:
	return min(START_SPEED + depth * SPEED_PER_METER, MAX_SPEED)

static func row_gap(speed: float) -> float:
	return BASE_ROW_GAP + (speed - START_SPEED) * ROW_GAP_PER_SPEED

static func zone_index_at(depth: float) -> int:
	var index := 0
	for i in ZONES.size():
		if depth >= ZONES[i].depth:
			index = i
	return index

static func pick_weighted(weights: Dictionary) -> String:
	var total := 0.0
	for key in weights:
		total += weights[key]
	var roll := randf() * total
	for key in weights:
		roll -= weights[key]
		if roll <= 0.0:
			return key
	return weights.keys().back()
