class_name LevelEditor
extends Node

const CAM_MOVE_SPEED_SLOW := 128
const CAM_MOVE_SPEED_FAST := 256

var cursor_tile_position := Vector2i.ZERO

const CURSOR_OFFSET := Vector2(-8, -8)

var mode := 0
var current_entity_selector: EditorTileSelector = null
var current_entity_id := ""
var current_entity_scene: PackedScene = null
var current_tile_source := 0
var current_tile_coords := Vector2i.ZERO
var current_tile_flip := Vector2.ZERO ## 1 = true, 0 = false, x = hori, y = vert

var last_placed_position := Vector2i.ZERO

var menu_open := false
var testing_level := false
var entity_tiles := [{}, {}, {}, {}, {}]

static var playing_level := false

var tile_list: Array[EditorTileSelector] = []

var tile_offsets := {}

signal level_start

var level: Level = null

var selected_tile_index := 0

var can_move_cam := true

static var music_track_list: Array[String] = [ "res://Assets/Audio/BGM/Silence.json","res://Assets/Audio/BGM/Athletic.json", "res://Assets/Audio/BGM/Autumn.json", "res://Assets/Audio/BGM/Beach.json", "res://Assets/Audio/BGM/Bonus.json", "res://Assets/Audio/BGM/Bowser.json", "res://Assets/Audio/BGM/FinalBowser.json", "res://Assets/Audio/BGM/Castle.json", "res://Assets/Audio/BGM/CoinHeaven.json", "res://Assets/Audio/BGM/Desert.json", "res://Assets/Audio/BGM/Garden.json", "res://Assets/Audio/BGM/GhostHouse.json", "res://Assets/Audio/BGM/Jungle.json", "res://Assets/Audio/BGM/Mountain.json", "res://Assets/Audio/BGM/Overworld.json", "res://Assets/Audio/BGM/Pipeland.json", "res://Assets/Audio/BGM/BooRace.json", "res://Assets/Audio/BGM/Sky.json", "res://Assets/Audio/BGM/Snow.json", "res://Assets/Audio/BGM/Space.json", "res://Assets/Audio/BGM/Underground.json", "res://Assets/Audio/BGM/Underwater.json", "res://Assets/Audio/BGM/Volcano.json", "res://Assets/Audio/BGM/Airship.json"]
var music_track_names: Array[String] = ["BGM_NONE", "BGM_ATHLETIC", "BGM_AUTUMN", "BGM_BEACH", "BGM_BONUS", "BGM_BOWSER", "BGM_FINALBOWSER", "BGM_CASTLE", "BGM_COINHEAVEN", "BGM_DESERT", "BGM_GARDEN", "BGM_GHOSTHOUSE", "BGM_JUNGLE", "BGM_MOUNTAIN", "BGM_OVERWORLD", "BGM_PIPELAND", "BGM_RACE", "BGM_SKY", "BGM_SNOW", "BGM_SPACE", "BGM_UNDERGROUND", "BGM_UNDERWATER", "BGM_VOLCANO", "BGM_AIRSHIP"]

enum TileType{TILE, ENTITY, TERRAIN}

var bgm_id := 0

var entity_id_map := {}

const MUSIC_TRACK_DIR := "res://Assets/Audio/BGM/"

var select_start := Vector2i.ZERO
var select_end := Vector2i.ZERO

signal close_confirm(save: bool)

signal connection_node_found(new_node: Node)

var sub_level_id := 0

static var sub_areas: Array = [null, null, null, null, null]

const BLANK_FILE := {"Info": {}, "Levels": [{}, {}, {}, {}, {}]}

static var level_file = {"Info": {}, "Levels": [{}, {}, {}, {}, {}]}

var current_layer := 0
@onready var tile_layer_nodes: Array[TileMapLayer] = [%TileLayer1, %TileLayer2, %TileLayer3, %TileLayer4, %TileLayer5]
@onready var entity_layer_nodes := [%EntityLayer1, %EntityLayer2, %EntityLayer3, %EntityLayer4, %EntityLayer5]

var copied_node: Node = null
var copied_tile_offset := Vector2.ZERO
var copied_tile_source_id := -1
var copied_tile_atlas_coors := Vector2i.ZERO
var copied_tile_terrain_id := -1


const CURSOR_ERASOR := preload("uid://d0j1my4kuapgb")
const CURSOR_PEN = preload("uid://bt0brcjv0efmw")
const CURSOR_PENCIL = preload("uid://c8oyhfvlv2gvh")
const CURSOR_RULER = preload("uid://cg2wkxnmjgplf")
const CURSOR_INSPECT = preload("uid://1l3foyjqeej")

var multi_selecting := false

var inspect_mode := false
var inspect_menu_open := false
var current_inspect_tile: Node = null

var selection_filter := ""
var current_tile_type := TileType.TERRAIN

static var level_author := ""
static var level_desc := ""
static var level_name := ""
static var difficulty := 0

var current_terrain_id := 0

static var load_play := false

signal tile_selected(tile_selector: EditorTileSelector)

var tile_menu_open := false

signal editor_start

enum EditorState{IDLE, TILE_MENU, MODIFYING_TILE, SAVE_MENU, SELECTING_TILE_SCENE, QUITTING, PLAYTESTING, TRACK_EDITING, CONNECTING}

var current_state := EditorState.IDLE

static var play_pipe_transition := false
static var play_door_transition := false

const BOUNDARY_CONNECT_TILE := Vector2i.ZERO

var undo_redo = UndoRedo.new()

func _ready() -> void:
	$TileMenu.hide()
	entity_id_map = JSON.parse_string(FileAccess.open("res://EntityIDMap.json", FileAccess.READ).get_as_text())
	DiscordManager.set_discord_status("In The Level Editor...")
	Global.level_editor = self
	playing_level = false
	menu_open = $TileMenu.visible
	Global.get_node("GameHUD").hide()
	Global.can_time_tick = false
	for i in get_tree().get_nodes_in_group("Selectors"):
		tile_list.append(i)
	var idx := 0
	for i in music_track_list:
		if i == "": continue
		$%LevelMusic.add_item(tr(music_track_names[idx]).to_upper())
		idx += 1
	load_level(0)
	await get_tree().process_frame
	Level.start_level_path = scene_file_path
	var layer_idx := 0
	for i in entity_layer_nodes:
		for x in i.get_children():
			entity_tiles[layer_idx][x.get_meta("tile_position")] = x
		layer_idx += 1
	Global.current_game_mode = Global.GameMode.LEVEL_EDITOR
	for i: Player in get_tree().get_nodes_in_group("Players"):
		i.recenter_camera()
	%LevelName.text = level_name
	%LevelAuthor.text = level_author
	%Description.text = level_desc

var last_recorded_frame := Vector2.ZERO

func _physics_process(delta: float) -> void:
	%TileCursor.hide()
	if [EditorState.IDLE, EditorState.CONNECTING].has(current_state) and not cursor_in_toolbar:
		handle_tile_cursor()
	if [EditorState.IDLE, EditorState.TRACK_EDITING, EditorState.CONNECTING].has(current_state):
		handle_camera(delta)
	if is_instance_valid(%ThemeName):
		%ThemeName.text = Global.level_theme
	handle_hud()
	if Input.is_action_just_pressed("editor_open_menu"):
		if current_state == EditorState.IDLE:
			open_tile_menu()
		elif current_state == EditorState.TILE_MENU:
			close_tile_menu()
	if Input.is_action_just_pressed("editor_play") and (current_state == EditorState.IDLE or current_state == EditorState.PLAYTESTING) and Global.current_game_mode == Global.GameMode.LEVEL_EDITOR:
		Checkpoint.passed_checkpoints.clear()
		if current_state == EditorState.PLAYTESTING:
			stop_testing()
		else:
			play_level()
	handle_player_trail()
	handle_layers()

func handle_player_trail() -> void:
	$PlayerTrail.modulate.a = int(current_state != EditorState.PLAYTESTING)
	if current_state == EditorState.PLAYTESTING:
		var target_player = get_tree().get_first_node_in_group("Players")
		if target_player == null:
			return
		var distance = last_placed_position.distance_to(target_player.global_position)
		if distance >= 32:
			record_player_frame()

func handle_hud() -> void:
	$Info.visible = not playing_level
	%Grid.modulate.a = int(not playing_level)
	%Tools.visible = not playing_level

func quit_editor() -> void:
	%QuitDialog.show()

signal level_saved

func open_tile_menu() -> void:
	$TileMenu.visible = true
	current_state = EditorState.TILE_MENU
	for i in get_tree().get_nodes_in_group("Selectors"):
		i.disabled = false
		i.update_visuals()

func close_tile_menu() -> void:
	$TileMenu.visible = false
	current_state = EditorState.IDLE
	for i in get_tree().get_nodes_in_group("Selectors"):
		i.disabled = false

func save_level_before_exit() -> void:
	tile_menu_open = true
	open_save_dialog()
	await level_saved
	go_back_to_menu()

func copy_node(tile_position := Vector2i.ZERO) -> void:
	if tile_layer_nodes[current_layer].get_used_cells().has(tile_position):
		var terrain_id = BetterTerrain.get_cell(tile_layer_nodes[current_layer], tile_position)
		if terrain_id != -2:
			copied_tile_terrain_id = terrain_id
			return
		mode = 0
		copied_tile_source_id = tile_layer_nodes[current_layer].get_cell_source_id(tile_position)
		copied_tile_atlas_coors = tile_layer_nodes[current_layer].get_cell_atlas_coords(tile_position)
	elif entity_tiles[current_layer].has(tile_position):
		copied_node = entity_tiles[current_layer][tile_position].duplicate()
		copied_tile_offset = entity_tiles[current_layer][tile_position].get_meta("tile_offset")

func cut_node(tile_position := Vector2i.ZERO) -> void:
	var old_copy = copied_node
	copy_node(tile_position)
	if copied_node != old_copy:
		remove_tile(tile_position)

func paste_node(tile_position := Vector2i.ZERO) -> void:
	place_tile(tile_position, true)

func go_back_to_menu() -> void:
	Global.transition_to_scene("res://Scenes/Levels/CustomLevelMenu.tscn")

func open_bindings_menu() -> void:
	$TileMenu/EditorKeybindsView.open()
	current_state = EditorState.SAVE_MENU
	await $TileMenu/EditorKeybindsView.closed
	current_state = EditorState.TILE_MENU

func open_save_dialog() -> void:
	current_state = EditorState.SAVE_MENU
	can_move_cam = false
	%SaveLevelDialog.show()
	menu_open = true

func stop_testing() -> void:
	if current_state == EditorState.IDLE:
		return
	cleanup()
	return_to_editor()
	

func cleanup() -> void:
	Global.reset_values()
	get_tree().paused = false
	Global.p_switch_timer = 0
	Global.cancel_score_tally()
	playing_level = !playing_level
	play_pipe_transition = false
	play_door_transition = false
	LevelPersistance.reset_states()
	KeyItem.total_collected = 0
	Global.get_node("GameHUD").visible = playing_level
	Global.p_switch_active = false
	if Global.current_game_mode == Global.GameMode.LEVEL_EDITOR:
		Global.time = level.time_limit
	elif Level.can_set_time and playing_level:
		Global.time = level.time_limit
	Global.can_time_tick = playing_level
	print(Global.can_time_tick)

func update_music() -> void:
	if music_track_list[bgm_id] != "":
		level.music = load(music_track_list[bgm_id].replace(".remap", ""))
	else:
		level.music = null

func play_level() -> void:
	clear_trail()
	$TileMenu.hide()
	menu_open = false
	update_music()
	reset_values_for_play()
	%Camera.enabled = false
	level_start.emit()
	if gizmos_visible == false:
		get_tree().call_group("Gizmos", "hide")
	get_tree().call_group("Players", "editor_level_start")
	save_current_level()
	current_state = EditorState.PLAYTESTING
	level.process_mode = Node.PROCESS_MODE_PAUSABLE
	handle_hud()
	$TrailTimer.start()

func return_to_editor() -> void:
	AudioManager.stop_all_music()
	level.music = null
	%Camera.global_position = get_viewport().get_camera_2d().get_screen_center_position()
	%Camera.reset_physics_interpolation()
	load_level(sub_level_id)
	get_tree().call_group("Gizmos", "show")
	%Camera.enabled = true
	%Camera.make_current()
	editor_start.emit()
	current_state = EditorState.IDLE
	level.process_mode = Node.PROCESS_MODE_DISABLED
	handle_hud()


func handle_camera(delta: float) -> void:
	var input_vector = Input.get_vector("editor_cam_left", "editor_cam_right", "editor_cam_up", "editor_cam_down")
	%Camera.global_position += input_vector * (CAM_MOVE_SPEED_FAST if Input.is_action_pressed("editor_cam_fast") else CAM_MOVE_SPEED_SLOW) * delta
	%Camera.global_position.y = clamp(%Camera.global_position.y, level.vertical_height + (get_viewport().get_visible_rect().size.y / 2), 32 - (get_viewport().get_visible_rect().size.y / 2))
	%Camera.global_position.x = clamp(%Camera.global_position.x, -256 + (get_viewport().get_visible_rect().size.x / 2), INF)

func handle_layers() -> void:
	if Input.is_action_just_pressed("layer_up"):
		current_layer += 1
	if Input.is_action_just_pressed("layer_down"):
		current_layer -= 1
	current_layer = clamp(current_layer, 0, entity_layer_nodes.size() - 1)
	var idx := 0
	for i in entity_layer_nodes:
		i.z_index = 0 if current_layer == idx or playing_level else -1
		i.modulate = Color(1, 1, 1, 1) if current_layer == idx or playing_level else Color(1, 1, 1, 0.5)
		tile_layer_nodes[idx].modulate = i.modulate
		tile_layer_nodes[idx].z_index = i.z_index - 1
		%LayerDisplay.get_child(idx).modulate = Color.WHITE if current_layer == idx else Color(0.1, 0.1, 0.1, 0.5)
		idx += 1
	%LayerLabel.text = "Layer " + str(current_layer + 1)

func save_level() -> void:
	level_author = %LevelAuthor.text
	level_desc = %Description.text
	level_name = %LevelName.text
	difficulty = %DifficultySlider.value
	var file_name = level_name.to_pascal_case() + ".lvl"
	%SaveLevelDialog.hide()
	menu_open = false
	save_current_level()
	level_file = $LevelSaver.save_level(level_name, level_author, level_desc, difficulty)
	$LevelSaver.write_file(level_file, file_name)
	%SaveDialog.text = str("'") +  file_name + "'" + " Saved." 
	%SaveAnimation.play("Show")
	current_state = EditorState.TILE_MENU
	level_saved.emit()

func close_save_menu() -> void:
	can_move_cam = true
	%SaveLevelDialog.hide()
	menu_open = false
	current_state = EditorState.TILE_MENU

func handle_tile_cursor() -> void:
	%TileCursor.show()
	var target_mouse_icon = null
	var snapped_position = ((%TileCursor.get_global_mouse_position() - CURSOR_OFFSET).snapped(Vector2(16, 16))) + CURSOR_OFFSET
	%TileCursor.global_position = (snapped_position)
	var old_index := selected_tile_index
	var tile_position = global_position_to_tile_position(snapped_position + Vector2(-8, -8))
	tile_position.y = clamp(tile_position.y, -30, 1)
	tile_position.x = clamp(tile_position.x, -16, INF)
	cursor_tile_position = tile_position

	inspect_mode = Input.is_action_pressed("editor_inspect") and not multi_selecting
	if inspect_mode and current_state == EditorState.IDLE:
		handle_inspection(tile_position)
		return
	
	if current_state == EditorState.IDLE:
		if Input.is_action_pressed("mb_left"):
			if Input.is_action_pressed("editor_select") and not multi_selecting:
				multi_select_start(tile_position)
			elif Input.is_action_pressed("editor_select") == false:
				multi_selecting = false
				match current_tile_type:
					TileType.TILE:
						place_tile(tile_position, current_layer, current_tile_coords, [current_tile_source])
					TileType.ENTITY:
						place_tile(tile_position, current_layer, current_entity_id)
					TileType.TERRAIN:
						place_tile(tile_position, current_layer, current_terrain_id)
				target_mouse_icon = (CURSOR_PENCIL)
			
		if Input.is_action_pressed("mb_right"):
			if Input.is_action_pressed("editor_select") and not multi_selecting:
				multi_select_start(tile_position)
				target_mouse_icon = (CURSOR_RULER)
			elif Input.is_action_pressed("editor_select") == false:
				multi_selecting = false
				remove_tile(tile_position)
				target_mouse_icon = (CURSOR_ERASOR)
		
		if Input.is_action_just_pressed("scroll_up"):
			selected_tile_index -= 1
		if Input.is_action_just_pressed("scroll_down"):
			selected_tile_index += 1
	
		if Input.is_action_just_pressed("editor_copy"):
			copy_node(tile_position)
		elif Input.is_action_just_pressed("editor_cut"):
			cut_node(tile_position)
		elif Input.is_action_pressed("ui_paste"):
			paste_node(tile_position)
	
		if Input.is_action_just_pressed("pick_tile"):
			pick_tile(tile_position)
	
		if Input.is_action_just_pressed("ui_undo"):
			undo()
		
		if Input.is_action_just_pressed("ui_redo"):
			redo()
	
	if current_state == EditorState.CONNECTING:
		if Input.is_action_just_pressed("mb_left"):
			if entity_tiles[current_layer].has(tile_position):
				if entity_tiles[current_layer][tile_position].get_node_or_null("SignalExposer") != null:
					connection_node_found.emit(entity_tiles[current_layer][tile_position])
					current_state = EditorState.MODIFYING_TILE
	
	handle_multi_selecting(tile_position)
	if old_index != selected_tile_index:
		selected_tile_index = wrap(selected_tile_index, 0, tile_list.size())
		on_tile_selected(tile_list[selected_tile_index])
		show_scroll_preview()
	
	Input.set_custom_mouse_cursor(target_mouse_icon)

func pick_tile(tile_position := Vector2i.ZERO) -> void:
	if tile_layer_nodes[current_layer].get_used_cells().has(tile_position):
		var terrain_id = BetterTerrain.get_cell(tile_layer_nodes[current_layer], tile_position)
		if terrain_id != -2:
			mode = 2
			current_terrain_id = terrain_id
			return
		mode = 0
		current_tile_source = tile_layer_nodes[current_layer].get_cell_source_id(tile_position)
		current_tile_coords = tile_layer_nodes[current_layer].get_cell_atlas_coords(tile_position)
	elif entity_tiles[current_layer].has(tile_position) and entity_tiles[current_layer][tile_position] is not Player:
		mode = 1

func handle_inspection(tile_position := Vector2i.ZERO) -> void:
	Input.set_custom_mouse_cursor(CURSOR_INSPECT)
	if Input.is_action_just_pressed("mb_left"):
		if entity_tiles[current_layer].get(tile_position) != null:
			open_tile_properties(entity_tiles[current_layer][tile_position])

func open_tile_properties(tile: Node2D) -> void:
	var properties = get_tile_properties(tile)
	var has_connection = tile_has_signal(tile)
	if has_connection == false and properties.is_empty():
		return
	
	current_inspect_tile = tile
	if properties.is_empty() == false:
		%TileModifierMenu.override_scenes = tile.get_node("EditorPropertyExposer").properties_force_selector
		%TileModifierMenu.properties = properties
	%TileModifierMenu.has_connection = has_connection
	%TileModifierMenu.editing_node = current_inspect_tile
	%TileModifierMenu.open()
	current_state = EditorState.MODIFYING_TILE
	await get_tree().process_frame
	%TileModifierMenu.update_minimum_size()
	%TileModifierMenu.position = tile.get_global_transform_with_canvas().origin
	%TileModifierMenu.position.x = clamp(%TileModifierMenu.position.x, 0, get_viewport().get_visible_rect().size.x - %TileModifierMenu.size.x - 2)
	%TileModifierMenu.position.y = clamp(%TileModifierMenu.position.y, 0, get_viewport().get_visible_rect().size.y - %TileModifierMenu.size.y - 2)

	await %TileModifierMenu.closed
	current_state = EditorState.IDLE

func multi_select_start(tile_position := Vector2i.ZERO) -> void:
	select_start = tile_position
	multi_selecting = true

func handle_multi_selecting(tile_position := Vector2i.ZERO) -> void:
	select_end = tile_position
	%MultiSelectRect.visible = multi_selecting
	var top_corner := select_start
	if select_start.x > select_end.x:
		top_corner.x = select_end.x
	if select_start.y > select_end.y:
		top_corner.y = select_end.y
	%MultiSelectRect.global_position = top_corner * 16
	%MultiSelectRect.size = abs(select_end - select_start) * 16 + Vector2i(16, 16)
	if multi_selecting:
		Input.set_custom_mouse_cursor(CURSOR_RULER)
		if Input.is_action_just_released("mb_left"): 
			match current_tile_type:
				TileType.TILE:
					mass_place(top_corner, select_start, select_end, current_layer, current_tile_coords, [current_tile_source])
				TileType.ENTITY:
					mass_place(top_corner, select_start, select_end, current_layer, current_entity_id)
				TileType.TERRAIN:
					mass_place(top_corner, select_start, select_end, current_layer, current_terrain_id)
			multi_selecting = false
		if Input.is_action_just_released("mb_right"): 
			mass_remove(top_corner, select_start, select_end)
			multi_selecting = false

func mass_place(top_corner := Vector2i.ZERO, select_start := Vector2i.ZERO, select_end := Vector2i.ZERO, layer_num := current_layer, thing_to_place = null, info := [], save_action := true) -> void:
	var area = save_area(top_corner, select_start, select_end, layer_num)
	var position := Vector2i.ZERO
	for x in abs(select_end.x - select_start.x) + 1:
		for y in abs(select_end.y - select_start.y) + 1:
			position = top_corner + Vector2i(x, y)
			place_tile(position, layer_num, thing_to_place, info, false)
	if save_action:
		undo_redo.create_action("Mass Place")
		undo_redo.add_do_method(mass_place.bind(top_corner, select_start, select_end, layer_num, thing_to_place, info, false))
		undo_redo.add_undo_method(replace_area.bind(top_corner, layer_num, area))
		undo_redo.commit_action(false)

func mass_remove(top_corner := Vector2i.ZERO, select_start := Vector2i.ZERO, select_end := Vector2i.ZERO, layer_num := current_layer, save_action := true) -> void:
	var area := []
	if save_action:
		area = save_area(top_corner, select_start, select_end, layer_num)
	for x in abs(select_end.x - select_start.x) + 1:
		for y in abs(select_end.y - select_start.y) + 1:
			var position = top_corner + Vector2i(x, y)
			remove_tile(position, layer_num, false)
	if save_action:
		undo_redo.create_action("Mass Remove")
		undo_redo.add_do_method(mass_remove.bind(top_corner, select_start, select_end, layer_num, false))
		undo_redo.add_undo_method(replace_area.bind(top_corner, layer_num, area))
		undo_redo.commit_action(false)

func replace_area(top_corner := Vector2i.ZERO, layer_num := current_layer, area := []) -> void:
	var x_pos := 0
	for x in area:
		var y_pos := 0
		for y in x:
			var position = top_corner + Vector2i(x_pos, y_pos)
			if y != null:
				if y is Array:
					place_tile(position, layer_num, y[1], [y[0]], false)
				else:
					place_tile(position, layer_num, y.duplicate(), [], false)
			else:
				remove_tile(position, layer_num, false)
			y_pos += 1
		x_pos += 1

func save_area(top_corner := Vector2i.ZERO, select_start := Vector2i.ZERO, select_end := Vector2i.ZERO, layer_num := current_layer) -> Array:
	var x_arr := []
	for x in abs(select_end.x - select_start.x) + 1:
		var y_arr := []
		for y in abs(select_end.y - select_start.y) + 1:
			var position = top_corner + Vector2i(x, y)
			var tile = null
			if entity_tiles[layer_num].get(position, null) != null:
				y_arr.append(entity_tiles[layer_num].get(position).duplicate())
			elif tile_layer_nodes[layer_num].get_used_cells().has(position):
				y_arr.append([tile_layer_nodes[layer_num].get_cell_source_id(position), tile_layer_nodes[layer_num].get_cell_atlas_coords(position)])
			else:
				y_arr.append(null)
		x_arr.append(y_arr)
	
	return x_arr

func show_scroll_preview() -> void:
	$TileCursor/Previews.show()
	for i in [$"TileCursor/Previews/-2", $"TileCursor/Previews/-1", $"TileCursor/Previews/0", $"TileCursor/Previews/1", $"TileCursor/Previews/2"]:
		var position = selected_tile_index + int(i.name)
		var selector = tile_list[wrap(position, 0, tile_list.size())]
		i.texture = selector.get_node("%Icon").texture
		i.get_node("Overlay").texture = selector.get_node("%SecondaryIcon").texture
		i.get_node("Overlay").region_rect = selector.get_node("%SecondaryIcon").region_rect
		i.region_rect = selector.get_node("%Icon").region_rect
	$TileCursor/Timer.start()
	await $TileCursor/Timer.timeout
	$TileCursor/Previews.hide()

func open_tile_selection_menu_scene_ref(selector: TilePropertySceneRef) -> void:
	open_tile_menu()
	current_state = EditorState.SELECTING_TILE_SCENE
	selection_filter = selector.editing_node.get_node("EditorPropertyExposer").filters[selector.tile_property_name]
	for i in get_tree().get_nodes_in_group("Selectors"):
		i.disabled = !i.has_meta(selection_filter) and selection_filter != ""
		i.update_visuals()
	var old_scene = current_entity_scene
	await tile_selected
	if is_instance_valid(selector) == false:
		return
	selector.set_scene(current_entity_selector)
	current_entity_scene = old_scene
	close_tile_menu()
	current_state = EditorState.MODIFYING_TILE

func start_signal_connection(node: Node, signal_name := "") -> void:
	current_state = LevelEditor.EditorState.CONNECTING

func on_tile_selected(selector: EditorTileSelector) -> void:
	current_tile_type = selector.type
	current_entity_selector = selector
	selected_tile_index = tile_list.find(selector)
	if selector.type == 1:
		current_entity_id = selector.entity_id
		current_entity_scene = load(entity_id_map[current_entity_id][0])
	elif selector.type == 2:
		current_terrain_id = selector.terrain_id
	else:
		current_tile_source = selector.source_id
		current_tile_coords = selector.tile_coords
		current_tile_flip = Vector2(selector.flip_h, selector.flip_v)
	tile_selected.emit(selector)

func reset_values_for_play() -> void:
	Global.score = 0
	Global.lives = 0
	Global.coins = 0
	cleanup()

func place_tile(tile_position := Vector2i.ZERO, layer_num := current_layer, tile_to_place = null, info := [], save_action := true) -> void:
	$TileCursor/Previews.hide()
	if tile_to_place is Vector2i:
		var alt_tile := 0
		if current_tile_flip.x != 0:
			alt_tile += TileSetAtlasSource.TRANSFORM_FLIP_H
		if current_tile_flip.y != 0:
			alt_tile += TileSetAtlasSource.TRANSFORM_FLIP_V
		var source = info[0]
		var atlas = tile_to_place
		if tile_layer_nodes[layer_num].get_cell_source_id(tile_position) == source and tile_layer_nodes[layer_num].get_cell_atlas_coords(tile_position) == atlas:
			return
		remove_tile(tile_position, layer_num, save_action)
		check_connect_boundary_tiles(tile_position, layer_num)
		tile_layer_nodes[layer_num].set_cell(tile_position, source, atlas, alt_tile)
	elif tile_to_place is int:
		var terrain_id = tile_to_place
		if BetterTerrain.get_cell(tile_layer_nodes[layer_num], tile_position) == terrain_id:
			return
		remove_tile(tile_position, layer_num, save_action)
		check_connect_boundary_tiles(tile_position, layer_num)
		BetterTerrain.set_cell(tile_layer_nodes[layer_num], tile_position, terrain_id)
	elif tile_to_place is String:
		var overlapping_tile = null
		var node: Node = null
		current_entity_scene = load(entity_id_map[tile_to_place][0])
		if entity_tiles[layer_num].get(tile_position) != null:
			overlapping_tile = entity_tiles[layer_num][tile_position]
			if overlapping_tile.get_meta("ID", "") == tile_to_place:
				return
		remove_tile(tile_position, layer_num, save_action)
		node = current_entity_scene.instantiate()
		if node.has_node("AmountLimiter"):
			if node.get_node("AmountLimiter").run_check(get_tree()):
				node.queue_free()
				Global.log_error("Only one of these is allowed in a room at a time!", false)
				return
		var spawn_offset := Vector2i.ZERO
		var split = entity_id_map[tile_to_place][1].split(",")
		spawn_offset = Vector2i(int(split[0]), int(split[1]))
		node.global_position = (tile_position * 16) + (Vector2i(8, 8) + spawn_offset)
		node.set_meta("tile_position", tile_position)
		node.set_meta("ID", tile_to_place)
		node.set_meta("layer", layer_num)
		entity_layer_nodes[layer_num].add_child(node)
		node.reset_physics_interpolation()
		entity_tiles[layer_num].set(tile_position, node)
	elif tile_to_place is Node:
		tile_to_place = tile_to_place.duplicate()
		if entity_tiles[layer_num].get(tile_position) != null:
			var overlapping_tile = entity_tiles[layer_num][tile_position]
			if overlapping_tile.get_meta("ID", "") == tile_to_place.get_meta("ID", ""):
				return
			remove_tile(tile_position, layer_num, save_action)
		entity_layer_nodes[layer_num].add_child(tile_to_place)
		entity_tiles[layer_num].set(tile_position, tile_to_place)
	
	if save_action:
		undo_redo.create_action("Place Tile")
		undo_redo.add_do_method(place_tile.bind(tile_position, layer_num, tile_to_place, info, false))
		undo_redo.add_undo_method(remove_tile.bind(tile_position, layer_num, false))
		undo_redo.commit_action(false)

	BetterTerrain.update_terrain_cell(tile_layer_nodes[layer_num], tile_position, true)

func check_connect_boundary_tiles(tile_position := Vector2i.ZERO, layer := 0) -> void:
	if tile_position.y > 0:
		tile_layer_nodes[layer].set_cell(tile_position + Vector2i.DOWN, 6, BOUNDARY_CONNECT_TILE)
	if tile_position.x <= -16:
		tile_layer_nodes[layer].set_cell(tile_position + Vector2i.LEFT, 6, BOUNDARY_CONNECT_TILE)
	if tile_position.y > 0 and tile_position.x <= -16:
		tile_layer_nodes[layer].set_cell(tile_position + Vector2i.LEFT + Vector2i.DOWN, 6, BOUNDARY_CONNECT_TILE)

func remove_tile(tile_position := Vector2i.ZERO, layer_num := current_layer, save_action := true) -> void:
	$TileCursor/Previews.hide()
	tile_layer_nodes[layer_num].set_cell(tile_position, -1)
	var old_node: Node = null
	BetterTerrain.update_terrain_cell(tile_layer_nodes[layer_num], tile_position, true)
	if entity_tiles[layer_num].get(tile_position) != null:
		if entity_tiles[layer_num].get(tile_position) is Player:
			return
		if save_action:
			old_node = entity_tiles[layer_num].get(tile_position).duplicate()
			print("Node Saved: ", old_node)
		entity_tiles[layer_num].get(tile_position).queue_free()
	else:
		entity_tiles[layer_num].erase(tile_position)
		return
	entity_tiles[layer_num].erase(tile_position)
	
	if save_action:
		undo_redo.create_action("Remove Tile")
		undo_redo.add_do_method(remove_tile.bind(tile_position, layer_num, false))
		undo_redo.add_undo_method(place_tile.bind(tile_position, layer_num, old_node, [], false))
		undo_redo.commit_action(false)

func global_position_to_tile_position(position := Vector2.ZERO) -> Vector2i:
	return Vector2i(position / 16)

func theme_selected(theme_idx := 0) -> void:
	ResourceSetterNew.cache.clear()
	AudioManager.current_level_theme = ""
	$Level.theme = Level.THEME_IDXS[theme_idx]
	Global.level_theme = $Level.theme
	Global.level_theme_changed.emit()

func time_selected(time_idx := 0) -> void:
	ResourceSetterNew.cache.clear()
	AudioManager.current_level_theme = ""
	level.theme_time = ["Day", "Night"][time_idx]
	Global.theme_time = ["Day", "Night"][time_idx]
	level.get_node("LevelBG").time_of_day = time_idx
	Global.level_theme_changed.emit()

func music_selected(music_idx := 0) -> void:
	bgm_id = music_idx

func campaign_selected(campaign_idx := 0) -> void:
	ResourceSetterNew.cache.clear()
	Global.current_campaign = ["SMB1", "SMBLL", "SMBS", "SMBANN"][campaign_idx]
	level.campaign = Global.current_campaign
	Global.level_theme_changed.emit()

func backscroll_toggled(new_value := false) -> void:
	level.can_backscroll = new_value

func height_limit_changed(new_value := 0) -> void:
	level.vertical_height = -new_value

func time_limit_changed(new_value := 0) -> void:
	level.time_limit = new_value

func low_gravity_toggled(new_value := false) -> void:
	Global.entity_gravity = 10 if new_value == false else 5
	for i: Player in get_tree().get_nodes_in_group("Players"):
		i.low_gravity = new_value

func transition_to_sublevel(sub_lvl_idx := 0) -> void:
	clear_trail()
	undo_redo.clear_history()
	Global.can_pause = false
	if Global.level_editor_is_playtesting():
		Global.do_fake_transition()
	else:
		save_current_level()
		PipeArea.exiting_pipe_id = -1
	load_level(sub_lvl_idx)
	Global.can_pause = true

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		%ControllerInputWarning.show()
	else:
		%ControllerInputWarning.hide()

func get_tile_properties(tile: Node) -> Array:
	var properties := []
	var old_properties := []
	if tile.get_node_or_null("EditorPropertyExposer") == null:
		return []
	
	var property_exposer: PropertyExposer = tile.get_node_or_null("EditorPropertyExposer")
	old_properties = tile.get_property_list()
	for i in old_properties:
		if property_exposer.properties.has(i.name):
			properties.append(i)
	return properties

func tile_has_signal(tile: Node) -> bool:
	return tile.get_node_or_null("SignalExposer") != null

const CUSTOM_LEVEL_BASE = ("res://Scenes/Levels/CustomLevelBase.tscn")

func save_current_level() -> void:
	sub_areas[sub_level_id] = level.duplicate()

func load_level(level_id := 0) -> void:
	var node = sub_areas[level_id]
	if node == null:
		node = load(CUSTOM_LEVEL_BASE).instantiate()
		node.sublevel_id = level_id
	elif node is PackedScene:
		node = node.instantiate()
	if level != null:
		level.queue_free()
	add_child(node)
	level = node
	sub_level_id = level_id
	update_references()
	reload_entity_tiles()
	if Global.level_editor_is_playtesting() == false:
		node.music = null
		node.process_mode = ProcessMode.PROCESS_MODE_DISABLED
	else:
		node.process_mode = ProcessMode.PROCESS_MODE_PAUSABLE

func convert_scenes_to_nodes() -> void:
	pass

func reload_entity_tiles() -> void:
	entity_tiles = [{}, {}, {}, {}, {}]
	var layer_idx := 0
	for layer in entity_layer_nodes:
		for child in layer.get_children():
			entity_tiles[layer_idx][child.get_meta("tile_position")] = child
		layer_idx += 1

func update_references() -> void:
	entity_layer_nodes = [level.get_node("EntityLayer1"), level.get_node("EntityLayer2"), level.get_node("EntityLayer3"), level.get_node("EntityLayer4"), level.get_node("EntityLayer5")]
	tile_layer_nodes = [level.get_node("TileLayer1"), level.get_node("TileLayer2"), level.get_node("TileLayer3"), level.get_node("TileLayer4"), level.get_node("TileLayer5")]
	update_menu_values()
	if level.music != null:
		bgm_id = music_track_list.find(level.music.resource_path)

func update_menu_values() -> void:
	%ThemeTime.selected = ["Day", "Night"].find(level.theme_time)
	if level.music != null:
		%LevelMusic.selected = music_track_list.find(level.music.resource_path)
	else:
		%LevelMusic.selected = 0
	%Campaign.selected = Global.CAMPAIGNS.find(level.campaign)
	%BackScroll.set_pressed_no_signal(level.can_backscroll)
	%HeightLimit.value = abs(level.vertical_height)
	%TimeLimit.value = level.time_limit
	%SubLevelID.selected = sub_level_id

func set_bg_value(value := 0, value_name := "") -> void:
	level.get_node("LevelBG").set(value_name, value)
	level.get_node("LevelBG").update_visuals()

func on_tree_exited() -> void:
	pass # Replace with function body.


var cursor_in_toolbar := false

func on_mouse_entered() -> void:
	cursor_in_toolbar = true

func undo() -> void:
	undo_redo.undo()

func redo() -> void:
	undo_redo.redo()

func on_mouse_exited() -> void:
	cursor_in_toolbar = false

func set_toolbar_tooltip(text := "") -> void:
	%ToolsName.show()
	%ToolsName.text = text

func clear_toolbar_tooltip(text := "") -> void:
	if %ToolsName.text == text:
		%ToolsName.hide()

var gizmos_visible := false

func toggle_gizmos(toggled := false) -> void:
	gizmos_visible = toggled

func clear_trail() -> void:
	for i in $PlayerTrail.get_children():
		i.queue_free()

func record_player_frame () -> void:
	var target_player = get_tree().get_first_node_in_group("Players")
	if target_player == null:
		return
	last_placed_position = target_player.global_position
	var frame = target_player.sprite.sprite_frames.get_frame_texture(target_player.sprite.animation, target_player.sprite.frame)
	var sprite = Sprite2D.new()
	sprite.texture = frame
	sprite.global_transform = target_player.sprite.global_transform
	sprite.modulate.a = 0.5
	$PlayerTrail.add_child(sprite)

func clear_level() -> void:
	sub_areas = [null, null, null, null, null]
	level_file = BLANK_FILE.duplicate_deep()
	load_level(0)
