extends Node
# Autoload singleton to manage persistent state across different scenes and dimensions.
# This prevents state loss during SceneManager transitions.

# Dictionary to hold various narrative progression flags.
var narrative_flags: Dictionary = {
	"alarm_disabled": false,
	"rent_reminder_heard": false,
	"shift_1_done": false,
	"quiz_started": false,
	"buff_confidence_active": false
}

# Player health tracking.
var player_max_hp: int = 50
var player_current_hp: int = 50

# Dimension Shift charge and currency.
var acquired_fragments: int = 0
var dimension_charge: int = 0
const MAX_CHARGE: int = 3

# Persistent master deck list.
var master_deck: Array = []

func _ready() -> void:
	# Initialize default state values.
	player_current_hp = player_max_hp
	dimension_charge = 0
	acquired_fragments = 0

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
		"buff_confidence_active": false
	}
	player_current_hp = player_max_hp
	dimension_charge = 0
	acquired_fragments = 0
	master_deck.clear()
