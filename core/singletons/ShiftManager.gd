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

# Increment the dimension shift charge when actions are taken in combat.
func add_charge() -> void:
	if GlobalState.dimension_charge < GlobalState.MAX_CHARGE:
		GlobalState.dimension_charge += 1
		EventBus.ui_charge_updated.emit(GlobalState.dimension_charge)

# Check if the player is ready to shift dimensions.
func can_shift() -> bool:
	return GlobalState.dimension_charge >= GlobalState.MAX_CHARGE

# Serialize active combat variables.
func serialize_combat(player_hp: int, enemy_name: String, enemy_hp: int, enemy_max_hp: int) -> void:
	cached_combat_exists = true
	cached_player_hp = player_hp
	cached_enemy_name = enemy_name
	cached_enemy_hp = enemy_hp
	cached_enemy_max_hp = enemy_max_hp
	
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
	
	var data = {
		"player_hp": cached_player_hp,
		"enemy_name": cached_enemy_name,
		"enemy_hp": cached_enemy_hp,
		"enemy_max_hp": cached_enemy_max_hp
	}
	
	# Keep cached state so we can resume multiple times if needed, 
	# but clear it when battle ends.
	return data

func clear_cache() -> void:
	cached_combat_exists = false
	cached_draw_pile.clear()
	cached_hand.clear()
	cached_discard_pile.clear()
