extends Node
# Autoload singleton to manage persistent state across different scenes and dimensions.
# This prevents state loss during SceneManager transitions.

# RATIONALE: Canonical list of all valid flag names. has_flag and set_flag warn on unknown keys,
# providing lightweight type safety without a full enum refactor.
const FLAG_NAMES: Array = [
	"alarm_disabled",
	"rent_reminder_heard",
	"shift_1_done",
	"quiz_started",
	"buff_courage_active",
	"buff_confidence_active",
	"locker_searched",
	"desk_searched",
	"guitar_played",
	"bed_slept",
	"peer1_talked",
	"peer2_talked",
	# Combat-specific flags (reset between combats via reset_combat_flags).
	"enemy_burning",             # Fireball secondary effect: enemy skips Defend next turn.
	"pack_leader_hint_shown",    # Pack Leader immunity hint fired once.
	"window_closed",             # Apartment window closed; triggers room darkening tween.
	"has_showered",              # Player has used the shower; gated for exiting the apartment.
	"scratch_found",             # Found the desk scratch after boss defeat; 9th fragment.
]

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
	"peer2_talked": false,
	
	# Combat-specific flags.
	"enemy_burning": false,
	"pack_leader_hint_shown": false,
	"window_closed": false,
	"has_showered": false,
	"scratch_found": false,
}

# The ending branch selected by the player at the end of the chapter ("dream" or "wake").
var chosen_ending: String = ""

# Tracks how many attack cards the player has played against Pack Leader without the confidence buff.
# Stored separately since it needs integer values, not booleans.
var pack_leader_attack_count: int = 0

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
	pack_leader_attack_count = 0
	# RATIONALE: Deck initialization is handled exclusively by DeckManager.initialize_deck,
	# which is called at the start of each combat. GlobalState only holds master_deck as a
	# persistent reference between scenes. Pre-populating here caused a dual-init with DeckManager.

# Check if a narrative flag is set.
# Emits a warning if the flag name is not in FLAG_NAMES to catch typos early.
func has_flag(flag_name: String) -> bool:
	if not FLAG_NAMES.has(flag_name):
		push_warning("GlobalState.has_flag: Unknown flag name '%s'" % flag_name)
	return narrative_flags.get(flag_name, false)

# Set a narrative flag.
# Emits a warning if the flag name is not in FLAG_NAMES to catch typos early.
func set_flag(flag_name: String, value: bool) -> void:
	if not FLAG_NAMES.has(flag_name):
		push_warning("GlobalState.set_flag: Unknown flag name '%s'" % flag_name)
	narrative_flags[flag_name] = value

# Reset combat-specific flags between combats.
func reset_combat_flags() -> void:
	narrative_flags["enemy_burning"] = false
	narrative_flags["pack_leader_hint_shown"] = false
	pack_leader_attack_count = 0

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
		"peer2_talked": false,
		"enemy_burning": false,
		"pack_leader_hint_shown": false,
		"window_closed": false,
		"has_showered": false,
		"scratch_found": false,
	}
	chosen_ending = ""
	pack_leader_attack_count = 0
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

