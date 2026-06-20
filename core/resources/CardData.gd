extends Resource
class_name CardData
# Resource script defining properties and execution logic for deckbuilder cards.

# Card classifications and details.
@export var card_name: String = "Strike"
@export var energy_cost: int = 1
@export var base_value: int = 6

# Types can be "Attack", "Defense", or "Special".
@export_enum("Attack", "Defense", "Special") var card_type: String = "Attack"

# Description of card behavior.
@export_multiline var description: String = "Deal X damage"

# Target modes: "single", "all", "self", "random".
@export_enum("single", "all", "self", "random") var target_mode: String = "single"

# Execute the card's specific action in combat.
func execute_effect(user: Node, targets: Array) -> void:
	# RATIONALE: The player acts through the CombatManager context itself rather than a separate "Player" node.
	# Thus, we directly query GlobalState for active buffs to scale player card values accordingly.
	var damage_multiplier: float = 1.0
	if GlobalState.has_flag("buff_confidence_active"):
		damage_multiplier = 2.0 # Confident buff doubles player card damage (2.0x multiplier)
	elif GlobalState.has_flag("buff_courage_active"):
		damage_multiplier = 1.5 # Courage buff increases player card damage by 1.5x

	match card_name:
		"Strike":
			if not targets.is_empty():
				var dmg = int(base_value * damage_multiplier)
				targets[0].take_damage(dmg)
		"Heavy Slash":
			if not targets.is_empty():
				var dmg = int(base_value * damage_multiplier)
				targets[0].take_damage(dmg)
		"Double Strike":
			if not targets.is_empty():
				var dmg = int(base_value * damage_multiplier)
				targets[0].take_damage(dmg)
				targets[0].take_damage(dmg)
		"Defend":
			user.gain_block(base_value)
		"Fortress":
			user.gain_block(base_value)
		"Counter Stance":
			user.gain_block(base_value)
			# RATIONALE: Counter Stance offers high hybrid value by defending and dealing 4 counter damage.
			if not targets.is_empty():
				targets[0].take_damage(4)
		"Fireball":
			# Deal damage to all targets in the list.
			for t in targets:
				var dmg = int(base_value * damage_multiplier)
				t.take_damage(dmg)
		"Thunder":
			# Deal damage to random targets from the list.
			if not targets.is_empty():
				var dmg = int(base_value * damage_multiplier)
				for i in range(2):
					var rand_idx = randi() % targets.size()
					targets[rand_idx].take_damage(dmg)
		_:
			push_error("CardData: Unknown card name " + card_name)
