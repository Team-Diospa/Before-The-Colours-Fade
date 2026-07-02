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
			# Standard single-target hit. The mechanical baseline.
			# canvas_tear = canvas_tear.wav per design doc (Strike card SFX)
			EventBus.play_sound.emit("canvas_tear")
			if not targets.is_empty():
				var dmg = int(base_value * damage_multiplier)
				targets[0].take_damage(dmg)
				
		"Heavy Slash":
			# RATIONALE: Heavy Slash is the block-breaker. It clears all enemy block first,
			# then deals full damage. Best against an enemy that just defended.
			# crash_metal = heavy_metal_crash per design doc (Heavy Slash card SFX)
			EventBus.play_sound.emit("crash_metal")
			if not targets.is_empty():
				var dmg = int(base_value * damage_multiplier)
				targets[0].clear_block()  # Strip enemy block before damage lands.
				targets[0].take_damage(dmg)
				
		"Double Strike":
			# RATIONALE: Hits twice but at half base_value per hit (rounded up).
			# Total damage equals base_value when unblocked, but each hit applies block separately.
			# Good against unshielded enemies, weak against high-block enemies.
			EventBus.play_sound.emit("double_slice")
			if not targets.is_empty():
				var half_dmg = int(ceil(base_value / 2.0) * damage_multiplier)
				targets[0].take_damage(half_dmg)
				targets[0].take_damage(half_dmg)
				
		"Defend":
			# Standard block. Lower base value than Fortress, but no side effects.
			# wood_impact = wood_impact.wav per design doc (Defend card SFX)
			EventBus.play_sound.emit("wood_impact")
			user.gain_block(base_value)
			
		"Fortress":
			# RATIONALE: The engineering defense card. Gaining a Fortress also generates 1 dimension
			# charge - the blueprint logic translates into both structural defense and dimensional power.
			# metal_clamp = metal_clamp_lock per design doc (Fortress card SFX)
			EventBus.play_sound.emit("metal_clamp")
			user.gain_block(base_value)
			ShiftManager.add_charge()
			
		"Counter Stance":
			# RATIONALE: Counter Stance converts incoming force into a counter-response (gear-brake metaphor).
			# Block value from base_value. Counter damage is always unscaled - it is a reaction, not an attack.
			# gear_click = mechanical_gear_click per design doc (Counter Stance card SFX)
			EventBus.play_sound.emit("gear_click")
			user.gain_block(base_value)
			if not targets.is_empty():
				targets[0].take_damage(4)  # Counter damage is fixed and unscaled.
				
		"Fireball":
			# RATIONALE: Fireball deals damage to all targets AND applies a burning flag.
			# On the enemy's next turn, the burning flag cancels their Defend intent, forcing an Attack.
			# We also immediately cancel any pending Defend action on the current turn.
			# bass_rumble = bass_rumble_boom per design doc (Fireball card SFX)
			EventBus.play_sound.emit("bass_rumble")
			for t in targets:
				var dmg = int(base_value * damage_multiplier)
				t.take_damage(dmg)
			GlobalState.set_flag("enemy_burning", true)
			if user.has_method("cancel_enemy_defend"):
				user.cancel_enemy_defend()
			
		"Thunder":
			# RATIONALE: Thunder is momentum and acceleration. It deals damage AND generates
			# 2 dimension charges instead of the standard 1, charging the shift mechanic faster.
			# Best used in the Pack Leader fight to reach the shift threshold quickly.
			# thunderclap = thunderclap per design doc (Thunder card SFX)
			EventBus.play_sound.emit("thunderclap")
			if not targets.is_empty():
				var dmg = int(base_value * damage_multiplier)
				targets[0].take_damage(dmg)
			# Generate 2 charges: call add_charge twice.
			ShiftManager.add_charge()
			ShiftManager.add_charge()
			
		_:
			push_error("CardData: Unknown card name " + card_name)
