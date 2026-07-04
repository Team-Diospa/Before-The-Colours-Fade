extends Node

@onready var play_unselected = $CanvasLayer/PlayUnselected
@onready var play_selected = $CanvasLayer/PlaySelected
@onready var new_unselected = $CanvasLayer/NewUnselected
@onready var new_selected = $CanvasLayer/NewSelected
@onready var opt_unselected = $CanvasLayer/OptUnselected
@onready var opt_selected = $CanvasLayer/OptSelected
@onready var exit_unselected = $CanvasLayer/ExitUnselected
@onready var exit_selected = $CanvasLayer/ExitSelected

@onready var btn_play = $CanvasLayer/BtnPlay
@onready var btn_new = $CanvasLayer/BtnNewGame
@onready var btn_opt = $CanvasLayer/BtnOptions
@onready var btn_exit = $CanvasLayer/BtnExit

func _ready() -> void:
	# Ensure Title Screen OST is playing when in main menu
	SceneManager.play_music("res://Assets/OST/Title Screen - OST 000.ogg", -2.0)
	
	# Hide all selected layers by default
	play_selected.visible = false
	new_selected.visible = false
	opt_selected.visible = false
	exit_selected.visible = false
	
	# Connect Play button
	btn_play.mouse_entered.connect(func(): play_selected.visible = true; play_unselected.visible = false)
	btn_play.mouse_exited.connect(func(): play_selected.visible = false; play_unselected.visible = true)
	btn_play.pressed.connect(_on_continue_pressed)
	
	# Connect New Game button
	btn_new.mouse_entered.connect(func(): new_selected.visible = true; new_unselected.visible = false)
	btn_new.mouse_exited.connect(func(): new_selected.visible = false; new_unselected.visible = true)
	btn_new.pressed.connect(_on_start_pressed) # For now, acts same as Play
	
	# Connect Options button
	btn_opt.mouse_entered.connect(func(): opt_selected.visible = true; opt_unselected.visible = false)
	btn_opt.mouse_exited.connect(func(): opt_selected.visible = false; opt_unselected.visible = true)
	btn_opt.pressed.connect(func(): 
		PauseManager._toggle_pause()
		PauseManager._show_settings()
	)
	
	# Connect Exit button
	btn_exit.mouse_entered.connect(func(): exit_selected.visible = true; exit_unselected.visible = false)
	btn_exit.mouse_exited.connect(func(): exit_selected.visible = false; exit_unselected.visible = true)
	btn_exit.pressed.connect(_on_quit_pressed)

func _on_continue_pressed() -> void:
	if SaveManager.has_save():
		SaveManager.load_game()
	else:
		_on_start_pressed()

func _on_start_pressed() -> void:
	GlobalState.reset_state()
	GlobalState.set_flag("game_started", true)
	# SceneManager handles fade out and transitions properly.
	SceneManager.transition_to_state("S_intro")

func _on_quit_pressed() -> void:
	get_tree().quit()
