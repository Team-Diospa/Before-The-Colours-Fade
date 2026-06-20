extends Node
# Autoload singleton to manage persistent state across different scenes and dimensions.
# This prevents state loss during SceneManager transitions.

# Dictionary to hold various narrative progression flags.
var narrative_flags: Dictionary = {
	"alarm_disabled": false,
	"rent_reminder_heard": false,
	"shift_1_done": false,
	"quiz_started": false,
	"buff_courage_active": false,
	"buff_confidence_active": false,
	
	# RATIONALE: Tracking exploration interactions globally to prevent exploits and re-triggering.
	"locker_searched": false,
	"desk_searched": false,
	"guitar_played": false,
	"bed_slept": false,
	"peer1_talked": false,
	"peer2_talked": false
}

# Player health tracking.
var player_max_hp: int = 50
var player_current_hp: int = 50

# Dimension Shift charge and currency.
var acquired_fragments: int = 0
var dimension_charge: int = 0
const MAX_CHARGE: int = 3

# RATIONALE: Temporary stat modifiers earned from exploration choices, applied to the first turn of combat.
var starting_energy_modifier: int = 0
var starting_block_modifier: int = 0
var starting_draw_modifier: int = 0

# Persistent master deck list.
var master_deck: Array = []

func _ready() -> void:
	# Initialize default state values.
	player_current_hp = player_max_hp
	dimension_charge = 0
	acquired_fragments = 0
	
	# RATIONALE: Pre-populate master deck with basic cards so they are visible in HUD before combat starts.
	var strike_res = load("res://data/cards/strike.tres")
	var defend_res = load("res://data/cards/defend.tres")
	if strike_res and defend_res and master_deck.is_empty():
		master_deck = [
			strike_res, strike_res, strike_res, strike_res,
			defend_res, defend_res, defend_res, defend_res
		]

# Check if a narrative flag is set.
func has_flag(flag_name: String) -> bool:
	return narrative_flags.get(flag_name, false)

# Set a narrative flag.
func set_flag(flag_name: String, value: bool) -> void:
	narrative_flags[flag_name] = value

# Reset all persistent state for new game / restart.
func reset_state() -> void:
	narrative_flags = {
		"alarm_disabled": false,
		"rent_reminder_heard": false,
		"shift_1_done": false,
		"quiz_started": false,
		"buff_courage_active": false,
		"buff_confidence_active": false,
		"locker_searched": false,
		"desk_searched": false,
		"guitar_played": false,
		"bed_slept": false,
		"peer1_talked": false,
		"peer2_talked": false
	}
	player_max_hp = 50
	player_current_hp = player_max_hp
	dimension_charge = 0
	acquired_fragments = 0
	starting_energy_modifier = 0
	starting_block_modifier = 0
	starting_draw_modifier = 0
	master_deck.clear()
	
	# Repopulate baseline cards on reset.
	var strike_res = load("res://data/cards/strike.tres")
	var defend_res = load("res://data/cards/defend.tres")
	if strike_res and defend_res:
		master_deck = [
			strike_res, strike_res, strike_res, strike_res,
			defend_res, defend_res, defend_res, defend_res
		]

