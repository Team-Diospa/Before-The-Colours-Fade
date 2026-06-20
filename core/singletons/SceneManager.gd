extends Node
# Autoload singleton to handle scene transitions and fade animations.
# This ensures deterministic loading of scenes according to game states.

# CanvasLayer for scene transition overlays (e.g., fade-to-black).
var overlay_layer: CanvasLayer
var fade_rect: ColorRect

func _ready() -> void:
	# Programmatically construct overlay UI to avoid scene dependencies.
	overlay_layer = CanvasLayer.new()
	overlay_layer.layer = 100 # Keep on top of all other layers
	add_child(overlay_layer)
	
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0) # Start fully transparent
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_layer.add_child(fade_rect)
	
	# Show the HUD initially since we load in the Apartment scene.
	call_deferred("_init_hud_on_start")

func _init_hud_on_start() -> void:
	# RATIONALE: Do not show the HUD when the game launches into the main menu.
	# The HUD is only shown when transitioning into an exploration scene.
	if has_node("/root/ExplorationHUD"):
		var current = get_tree().current_scene
		if current and current.scene_file_path != "res://scenes/ui/main_menu.tscn":
			get_node("/root/ExplorationHUD").show_hud()

# Transition to a target state by path mapping.
func transition_to_state(target_state: String) -> void:
	var target_scene_path: String = ""
	match target_state:
		"S_apt":
			target_scene_path = "res://scenes/exploration/apartment.tscn"
			if has_node("/root/ExplorationHUD"):
				get_node("/root/ExplorationHUD").show_hud()
		"S_hall":
			target_scene_path = "res://scenes/exploration/hallway.tscn"
			if has_node("/root/ExplorationHUD"):
				get_node("/root/ExplorationHUD").show_hud()
		"S_dream1":
			target_scene_path = "res://scenes/combat/grassy_field.tscn"
			if has_node("/root/ExplorationHUD"):
				get_node("/root/ExplorationHUD").hide_hud()
		"S_class":
			target_scene_path = "res://scenes/exploration/classroom.tscn"
			if has_node("/root/ExplorationHUD"):
				get_node("/root/ExplorationHUD").show_hud()
		"S_dream2", "S_dream2_resume":
			target_scene_path = "res://scenes/combat/burning_village.tscn"
			if has_node("/root/ExplorationHUD"):
				get_node("/root/ExplorationHUD").hide_hud()
		_:
			push_error("SceneManager: Unknown target state: " + target_state)
			return
			
	# Trigger the transition process with fade effect.
	_change_scene_with_fade(target_scene_path)

# Return to the main menu. Called by PauseManager when the player selects Main Menu.
func transition_to_state_menu() -> void:
	if has_node("/root/ExplorationHUD"):
		get_node("/root/ExplorationHUD").hide_hud()
	_change_scene_with_fade("res://scenes/ui/main_menu.tscn")

# Perform fade-out, scene change, and fade-in.
func _change_scene_with_fade(scene_path: String) -> void:
	# Block user input during transition.
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Fade to black.
	var tween_out = create_tween()
	tween_out.tween_property(fade_rect, "color", Color(0, 0, 0, 1), 0.5)
	await tween_out.finished
	
	# Perform the actual Godot scene transition.
	var change_result = get_tree().change_scene_to_file(scene_path)
	if change_result != OK:
		push_error("SceneManager: Failed to change scene to " + scene_path)
		
	# Wait one frame for the tree to update.
	await get_tree().process_frame
	
	# Fade back to transparent.
	var tween_in = create_tween()
	tween_in.tween_property(fade_rect, "color", Color(0, 0, 0, 0), 0.5)
	await tween_in.finished
	
	# Release input blocking.
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
