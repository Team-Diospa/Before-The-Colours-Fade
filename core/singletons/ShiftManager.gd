extends Node
# Autoload singleton to handle Dimension Shifting.
# Manages serialization/deserialization of combat states to allow shifting mid-battle.

# Serialized combat state cache.
var cached_combat_exists: bool = false
var cached_enemy_hp: int = 0
var cached_enemy_max_hp: int = 0
var cached_enemy_name: String = ""
var cached_player_hp: int = 0
var cached_draw_pile: Array = []
var cached_hand: Array = []
var cached_discard_pile: Array = []
var cached_can_reroll: bool = true
var cached_can_retain: bool = true

# RATIONALE: Additional cache variables to track tactical combat status across shift boundaries, 
# preventing the exploit where shifting restores player energy, block, or card count.
var cached_player_energy: int = 3
var cached_player_block: int = 0
var cached_enemy_intent: String = ""
var cached_enemy_intent_value: int = 0
var cached_active_enemies: Array = []
var cached_current_stage_idx: int = 0

# Increment the dimension shift charge when actions are taken in combat.
func add_charge() -> void:
	if GlobalState.dimension_charge < GlobalState.MAX_CHARGE:
		GlobalState.dimension_charge += 1
		EventBus.ui_charge_updated.emit(GlobalState.dimension_charge)

# Check if the player is ready to shift dimensions.
func can_shift() -> bool:
	return GlobalState.dimension_charge >= GlobalState.MAX_CHARGE

# Serialize active combat variables.
func serialize_combat(player_hp: int, player_energy: int, player_block: int, enemy_name: String, enemy_hp: int, enemy_max_hp: int, enemy_intent: String, enemy_intent_value: int, active_enemies: Array = [], current_stage_idx: int = 0) -> void:
	cached_combat_exists = true
	cached_player_hp = player_hp
	cached_player_energy = player_energy
	cached_player_block = player_block
	cached_enemy_name = enemy_name
	cached_enemy_hp = enemy_hp
	cached_enemy_max_hp = enemy_max_hp
	cached_enemy_intent = enemy_intent
	cached_enemy_intent_value = enemy_intent_value
	
	# RATIONALE: Store deep copy of active enemies data structures (except nodes like Panel and Sprite).
	cached_active_enemies = []
	for enemy in active_enemies:
		var enemy_copy = enemy.duplicate()
		# Clear node references since they cannot be serialized across scenes.
		enemy_copy["sprite"] = null
		enemy_copy["panel"] = null
		enemy_copy["target_btn"] = null
		cached_active_enemies.append(enemy_copy)
		
	cached_current_stage_idx = current_stage_idx
	
	# Duplicate arrays to prevent reference sharing.
	cached_draw_pile = DeckManager.draw_pile.duplicate()
	cached_hand = DeckManager.hand.duplicate()
	cached_discard_pile = DeckManager.discard_pile.duplicate()
	cached_can_reroll = DeckManager.can_reroll
	cached_can_retain = DeckManager.can_retain

# Restore variables into DeckManager and clear cache.
func deserialize_combat() -> Dictionary:
	if not cached_combat_exists:
		return {}
		
	DeckManager.draw_pile = cached_draw_pile.duplicate()
	DeckManager.hand = cached_hand.duplicate()
	DeckManager.discard_pile = cached_discard_pile.duplicate()
	DeckManager.can_reroll = cached_can_reroll
	DeckManager.can_retain = cached_can_retain
	
	# RATIONALE: Packages all serialized properties into a return dictionary for CombatManager to apply.
	var data = {
		"player_hp": cached_player_hp,
		"player_energy": cached_player_energy,
		"player_block": cached_player_block,
		"enemy_name": cached_enemy_name,
		"enemy_hp": cached_enemy_hp,
		"enemy_max_hp": cached_enemy_max_hp,
		"enemy_intent": cached_enemy_intent,
		"enemy_intent_value": cached_enemy_intent_value,
		"active_enemies": cached_active_enemies.duplicate(true),
		"current_stage_idx": cached_current_stage_idx
	}
	
	return data

func clear_cache() -> void:
	cached_combat_exists = false
	cached_player_hp = 0
	cached_player_energy = 3
	cached_player_block = 0
	cached_enemy_name = ""
	cached_enemy_hp = 0
	cached_enemy_max_hp = 0
	cached_enemy_intent = ""
	cached_enemy_intent_value = 0
	cached_can_reroll = true
	cached_can_retain = true
	cached_draw_pile.clear()
	cached_hand.clear()
	cached_discard_pile.clear()
	cached_active_enemies.clear()
	cached_current_stage_idx = 0

