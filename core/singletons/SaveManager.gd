extends Node
# Autoload singleton to handle persistent save/load operations.
# RATIONALE: Saving and loading must persist across all scenes, writing state to a localized JSON file.
# Implements robust error handling and logs actions for verification and manual debugging.

const SAVE_PATH: String = "user://save.json"

# Checks if a save file exists in the user directory.
# RATIONALE: Used by Main Menu and UI controls to enable/disable Continue options.
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

# Saves the current game state, including scene location, narrative progress, stats, and deck inventory.
# Returns true if the save was successful, false otherwise.
func save_game(scene_path: String) -> bool:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: Failed to open save file for writing: %d" % FileAccess.get_open_error())
		return false
	
	var save_data = {}
	save_data["current_scene"] = scene_path
	
	# Serialize GlobalState parameters
	var gs_data = {}
	gs_data["narrative_flags"] = GlobalState.narrative_flags.duplicate()
	gs_data["pack_leader_attack_count"] = GlobalState.pack_leader_attack_count
	gs_data["player_max_hp"] = GlobalState.player_max_hp
	gs_data["player_current_hp"] = GlobalState.player_current_hp
	gs_data["acquired_fragments"] = GlobalState.acquired_fragments
	gs_data["dimension_charge"] = GlobalState.dimension_charge
	gs_data["starting_energy_modifier"] = GlobalState.starting_energy_modifier
	gs_data["starting_block_modifier"] = GlobalState.starting_block_modifier
	gs_data["starting_draw_modifier"] = GlobalState.starting_draw_modifier
	
	# Serialize master_deck by saving resource paths (strings) rather than object instances.
	var deck_paths = []
	for card in GlobalState.master_deck:
		if card != null and card.resource_path != "":
			deck_paths.append(card.resource_path)
	gs_data["master_deck"] = deck_paths
	
	save_data["global_state"] = gs_data
	
	var json_string = JSON.stringify(save_data)
	file.store_string(json_string)
	file.close()
	
	print("SaveManager: Game state successfully saved to: ", SAVE_PATH)
	return true

# Loads the saved game state from save.json, reinstantiates the deck, and transitions to the saved scene.
# Returns true if load was successful, false otherwise.
func load_game() -> bool:
	if not has_save():
		push_warning("SaveManager: No save file found.")
		return false
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager: Failed to open save file for reading: %d" % FileAccess.get_open_error())
		return false
		
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		push_error("SaveManager: JSON parse error: %s on line %d" % [json.get_error_message(), json.get_error_line()])
		return false
		
	var save_data = json.data
	if typeof(save_data) != TYPE_DICTIONARY:
		push_error("SaveManager: Save data is not a Dictionary.")
		return false
		
	var gs_data = save_data.get("global_state", {})
	if typeof(gs_data) == TYPE_DICTIONARY:
		# Restore narrative flags (only overwrite keys that exist in GlobalState to prevent corruption)
		var saved_flags = gs_data.get("narrative_flags", {})
		for key in saved_flags.keys():
			if GlobalState.narrative_flags.has(key):
				GlobalState.narrative_flags[key] = saved_flags[key]
		
		# Restore numerical stats and states
		GlobalState.pack_leader_attack_count = int(gs_data.get("pack_leader_attack_count", 0))
		GlobalState.player_max_hp = int(gs_data.get("player_max_hp", 50))
		GlobalState.player_current_hp = int(gs_data.get("player_current_hp", 50))
		GlobalState.acquired_fragments = int(gs_data.get("acquired_fragments", 0))
		GlobalState.dimension_charge = int(gs_data.get("dimension_charge", 0))
		GlobalState.starting_energy_modifier = int(gs_data.get("starting_energy_modifier", 0))
		GlobalState.starting_block_modifier = int(gs_data.get("starting_block_modifier", 0))
		GlobalState.starting_draw_modifier = int(gs_data.get("starting_draw_modifier", 0))
		
		# Re-load card resource instances from saved resource paths.
		var deck_paths = gs_data.get("master_deck", [])
		var loaded_deck = []
		for path in deck_paths:
			var res = load(path)
			if res != null:
				loaded_deck.append(res)
		GlobalState.master_deck = loaded_deck

	var scene_path = save_data.get("current_scene", "")
	if scene_path != "":
		print("SaveManager: Resuming game at scene: ", scene_path)
		# Request SceneManager to load scene path and restore corresponding HUD visibility.
		if SceneManager.has_method("transition_to_scene_path"):
			SceneManager.transition_to_scene_path(scene_path)
		else:
			# Fallback if SceneManager hasn't been updated yet.
			SceneManager._change_scene_with_fade(scene_path)
		return true
		
	push_error("SaveManager: Current scene path is missing or invalid in save data.")
	return false
