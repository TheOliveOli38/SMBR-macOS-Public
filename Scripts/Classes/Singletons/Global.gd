extends Node

var level_theme := "Overworld":
	set(value):
		level_theme = value
		level_theme_changed.emit()
var theme_time := "Day":
	set(value):
		theme_time = value
		level_time_changed.emit()

signal level_theme_changed
signal level_time_changed

const BASE64_CHARSET := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

const VERSION_CHECK_URL := "https://raw.githubusercontent.com/JHDev2006/smb1r-version/refs/heads/main/version.txt"
@onready var screen_shaker: Node = $ScreenShaker

var entity_gravity := 10.0
var entity_max_fall_speed := 280

var level_editor: LevelEditor = null
var current_level: Level = null

var second_quest := false
var extra_worlds_win := false
const lang_codes := ["en", "fr", "es", "de", "it", "pt_br", "pl", "tr", "ru", "jp", "fil", "id", "gal"]

var config_path : String = get_config_path()

var rom_path := ""
var rom_assets_exist := false
var ROM_POINTER_PATH = config_path.path_join("rom_pointer.smb")
var ROM_PATH = config_path.path_join("baserom.nes")
var ROM_ASSETS_PATH = config_path.path_join("resource_packs/BaseAssets")
const ROM_PACK_NAME := "BaseAssets"
const ROM_ASSETS_VERSION := 1

var server_version := -1
var current_version := -1
var version_number := ""

const LEVEL_THEMES := {
	"SMB1": SMB1_LEVEL_THEMES,
	"SMBLL": SMB1_LEVEL_THEMES,
	"SMBANN": SMB1_LEVEL_THEMES,
	"SMBS": SMBS_LEVEL_THEMES
}

var custom_campaigns := []
var custom_pack := ""
var custom_level_idx := 0
var current_custom_campaign := ""

const SMB1_LEVEL_THEMES := ["Overworld", "Desert", "Snow", "Jungle", "Desert", "Snow", "Jungle", "Overworld", "Space", "Autumn", "Pipeland", "Skyland", "Volcano"]
const SMBS_LEVEL_THEMES := ["Overworld", "Garden", "Beach", "Mountain", "Garden", "Beach", "Mountain", "Overworld", "Autumn", "Pipeland", "Skyland", "Volcano", "Fuck"]

const FORCE_NIGHT_THEMES := ["Space"]
const FORCE_DAY_THEMES := []

signal text_shadow_changed

@onready var player_ghost: PlayerGhost = $PlayerGhost

var debugged_in := true

var score_tween = null
var time_tween = null

var total_deaths := 0

var portable_mode := false
var checked_portable := false


var score := 0:
	set(value):
		if disco_mode == true:
			if value > score:
				var diff = value - score
				score = score + (diff * 1)
			else:
				score = value
		else:
			score = value
var coins := 0:
	set(value):
		coins = value
		if coins >= 100:#
			if Settings.file.difficulty.inf_lives == 0 and (Global.current_game_mode != Global.GameMode.CHALLENGE and Global.current_campaign != "SMBANN"):
				lives += floor(coins / 100.0)
				AudioManager.play_sfx("1_up", get_viewport().get_camera_2d().get_screen_center_position())
			coins = coins % 100
var time := 300
var lives := 3
var world_num := 1

var level_num := 1
var disco_mode := false

enum Room{MAIN_ROOM, BONUS_ROOM, COIN_HEAVEN, PIPE_CUTSCENE, TITLE_SCREEN}

const room_strings := ["MainRoom", "BonusRoom", "CoinHeaven", "PipeCutscene", "TitleScreen"]

var current_room: Room = Room.MAIN_ROOM

signal transition_finished
var transitioning_scene := false
var awaiting_transition := false

signal level_complete_begin
signal score_tally_finished

var achievements := "0000000000000000000000000000"

const LSS_GAME_ID := 5

enum AchievementID{
	SMB1_CLEAR, SMBLL_CLEAR, SMBS_CLEAR, SMBANN_CLEAR,
	SMB1_CHALLENGE, SMBLL_CHALLENGE, SMBS_CHALLENGE,
	SMB1_BOO, SMBLL_BOO, SMBS_BOO,
	SMB1_GOLD_BOO, SMBLL_GOLD_BOO, SMBS_GOLD_BOO,
	SMB1_BRONZE, SMBLL_BRONZE, SMBS_BRONZE,
	SMB1_SILVER, SMBLL_SILVER, SMBS_SILVER,
	SMB1_GOLD, SMBLL_GOLD, SMBS_GOLD,
	SMB1_RUN, SMBLL_RUN, SMBS_RUN,
	ANN_PRANK, SMBLL_WORLD9,
	COMPLETIONIST
}

const HIDDEN_ACHIEVEMENTS := [AchievementID.COMPLETIONIST]

var can_time_tick := true:
	set(value):
		can_time_tick = value
		if value == false:
			pass

var player_power_states := "0000"

var connected_players := 1

const CAMPAIGNS := ["SMB1", "SMBLL", "SMBS", "SMBANN"]

var player_characters := [0, 0, 0, 0]:
	set(value):
		player_characters = value
		player_characters_changed.emit()
signal player_characters_changed

signal disco_level_continued

signal frame_rule

var hard_mode := false

var current_campaign := "SMB1"

var death_load := false

var tallying_score := false

var in_title_screen := false

var game_paused := false
var can_pause := true

var fade_transition := false

enum GameMode{NONE, CAMPAIGN, BOO_RACE, CHALLENGE, MARATHON, MARATHON_PRACTICE, LEVEL_EDITOR, CUSTOM_LEVEL, DISCO}

const game_mode_strings := ["Default", "Campaign", "BooRace", "Challenge", "Marathon", "MarathonPractice", "LevelEditor", "CustomLevel", "Disco"]

var current_game_mode: GameMode = GameMode.NONE

var high_score := 0
var game_beaten := false

signal p_switch_toggle
var p_switch_active := false
var p_switch_timer := 0.0
var p_switch_timer_paused := false

var debug_mode := false

var custom_campaign_jsons := {}

var level_sequence_captured := false

func _ready() -> void:
	current_version = get_version_number()
	get_server_version()
	if OS.is_debug_build():
		debug_mode = false
	setup_config_dirs()
	check_for_rom()
	load_default_translations()
	level_theme_changed.connect(load_default_translations)

func setup_config_dirs() -> void:
	var dirs = [
		"custom_characters",
		"custom_levels",
		"logs",
		"marathon_recordings",
		"resource_packs",
		"saves",
		"screenshots",
		"level_packs"
	]

	for d in dirs:
		var full_path = Global.config_path.path_join(d)
		if not DirAccess.dir_exists_absolute(full_path):
			DirAccess.make_dir_recursive_absolute(full_path)

func get_config_path() -> String:
	var exe_path := OS.get_executable_path()
	var exe_dir  := exe_path.get_base_dir()
	var portable_flag := exe_dir.path_join("portable.txt")
	
	# Test that exe dir is writeable, if not fallback to user://
	if FileAccess.file_exists(portable_flag):
		var test_file = exe_dir.path_join("test.txt")
		var f = FileAccess.open(test_file, FileAccess.WRITE)
		if f:
			f.close()
			var dir = DirAccess.open(exe_dir)
			if dir:
				dir.remove(test_file.get_file())
			var local_dir = exe_dir.path_join("config")
			if not DirAccess.dir_exists_absolute(local_dir):
				DirAccess.make_dir_recursive_absolute(local_dir)
			return local_dir
		else:
			push_warning("Portable flag found but exe directory is not writeable. Falling back to user://")
	return "user://"

func check_for_rom() -> void:
	rom_path = ""
	rom_assets_exist = false
	if FileAccess.file_exists(Global.ROM_PATH) == false:
		return
	var path = Global.ROM_PATH 
	if FileAccess.file_exists(path):
		if ROMVerifier.is_valid_rom(path):
			rom_path = path
	if DirAccess.dir_exists_absolute(ROM_ASSETS_PATH):
		var pack_json: String = FileAccess.get_file_as_string(ROM_ASSETS_PATH + "/pack_info.json")
		var pack_dict: Dictionary = JSON.parse_string(pack_json)
		if pack_dict.get("version", -1) == ROM_ASSETS_VERSION:
			rom_assets_exist = true 
		else:
			ResourceGenerator.updating = true
			OS.move_to_trash(ROM_ASSETS_PATH)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("debug_reload"):
		ResourceSetter.cache.clear()
		ResourceSetterNew.clear_cache()
		ResourceGetter.cache.clear()
		AudioManager.current_level_theme = ""
		level_theme_changed.emit()
		TranslationServer.reload_pseudolocalization()
		log_comment("Reloaded resource packs!")
	
	if Input.is_action_just_pressed("toggle_fps_count"):
		%FPSCount.visible = !%FPSCount.visible
	%FPSCount.text = str(int(Engine.get_frames_per_second())) + " FPS"

	handle_p_switch(delta)
	if Input.is_key_label_pressed(KEY_F11) and debug_mode == false and OS.is_debug_build():
		AudioManager.play_global_sfx("switch")
		debug_mode = true
		log_comment("Debug Mode enabled! some bugs may occur!")
		
	if Input.is_action_just_pressed("ui_screenshot"):
		take_screenshot()

func take_screenshot() -> void:
	var img: Image = get_viewport().get_texture().get_image()
	var filename = Global.config_path.path_join("screenshots/screenshot_" + str(int(Time.get_unix_time_from_system())) + ".png")
	var err = img.save_png(filename)
	if !err:
		log_comment("Screenshot Saved!")
	else:
		log_error(error_string(err))

func handle_p_switch(delta: float) -> void:
	if p_switch_active and get_tree().paused == false:
		if p_switch_timer_paused == false:
			p_switch_timer -= delta
		if p_switch_timer <= 0:
			p_switch_active = false
			p_switch_toggle.emit()
			AudioManager.stop_music_override(AudioManager.MUSIC_OVERRIDES.PSWITCH)

func get_build_time() -> void:
	print(int(Time.get_unix_time_from_system()))

func get_version_number() -> int:
	var number = (FileAccess.open("res://version.txt", FileAccess.READ).get_as_text())
	version_number = str(number)
	return int(number)

func player_action_pressed(action := "", player_id := 0) -> bool:
	return Input.is_action_pressed(action + "_" + str(player_id))

func player_action_just_pressed(action := "", player_id := 0) -> bool:
	return Input.is_action_just_pressed(action + "_" + str(player_id))

func player_action_just_released(action := "", player_id := 0) -> bool:
	return Input.is_action_just_released(action + "_" + str(player_id))

func tally_time() -> void:
	if tallying_score:
		return
	$ScoreTally.play()
	tallying_score = true
	var target_score = score + (time * 50)
	score_tween = create_tween()
	time_tween = create_tween()
	var duration = float(time) / 120
	
	score_tween.tween_property(self, "score", target_score, duration)
	time_tween.tween_property(self, "time", 0, duration)
	await score_tween.finished
	tallying_score = false
	$ScoreTally.stop()
	$ScoreTallyEnd.play()
	score_tally_finished.emit()

func cancel_score_tally() -> void:
	if score_tween != null:
		score_tween.kill()
	if time_tween != null:
		time_tween.kill()
	tallying_score = false
	$ScoreTally.stop()

func activate_p_switch() -> void:
	if p_switch_active == false:
		p_switch_toggle.emit()
	AudioManager.set_music_override(AudioManager.MUSIC_OVERRIDES.PSWITCH, 99, false)
	p_switch_timer = 10
	p_switch_active = true

func reset_values() -> void:
	PlayerGhost.idx = 0
	Checkpoint.passed_checkpoints.clear()
	Checkpoint.sublevel_id = 0
	Global.total_deaths = 0
	Door.unlocked_doors = []
	Door.exiting_door_id = -1
	Checkpoint.unlocked_doors = []
	KeyItem.total_collected = 0
	Checkpoint.keys_collected = 0
	Broadcaster.active_channels = []
	Level.start_level_path = Level.get_scene_string(Global.world_num, Global.level_num)
	LevelPersistance.reset_states()
	Level.first_load = true
	Level.can_set_time = true
	Level.in_vine_level = false
	Level.vine_return_level = ""
	Level.vine_warp_level = ""
	p_switch_active = false
	p_switch_timer = 0.0

func clear_saved_values() -> void:
	coins = 0
	score = 0
	lives = 3
	player_power_states = "0000"

func transition_to_scene(scene_path = "") -> void:
	Global.fade_transition = bool(Settings.file.visuals.transition_animation)
	if transitioning_scene:
		return
	transitioning_scene = true
	if fade_transition:
		$Transition/AnimationPlayer.play("FadeIn")
		await $Transition/AnimationPlayer.animation_finished
		await get_tree().create_timer(0.1, true).timeout
	else:
		%TransitionBlock.modulate.a = 1
		$Transition.show()
		await get_tree().create_timer(0.1, true).timeout
	if scene_path is String:
		get_tree().change_scene_to_file(scene_path)
	elif scene_path is PackedScene:
		get_tree().change_scene_to_packed(scene_path)
	await get_tree().scene_changed
	await get_tree().create_timer(0.15, true).timeout
	if fade_transition:
		$Transition/AnimationPlayer.play_backwards("FadeIn")
	else:
		$Transition/AnimationPlayer.play("RESET")
		$Transition.hide()
	transitioning_scene = false
	transition_finished.emit()



func do_fake_transition(duration := 0.2) -> void:
	if fade_transition:
		$Transition/AnimationPlayer.play("FadeIn")
		await $Transition/AnimationPlayer.animation_finished
		await get_tree().create_timer(duration, false).timeout
		$Transition/AnimationPlayer.play_backwards("FadeIn")
	else:
		%TransitionBlock.modulate.a = 1
		$Transition.show()
		await get_tree().create_timer(duration + 0.05, false).timeout
		$Transition.hide()

func freeze_screen() -> void:
	if Settings.file.video.visuals == 1:
		return
	$Transition.show()
	$Transition/Freeze.show()
	$Transition/Freeze.texture = ImageTexture.create_from_image(get_viewport().get_texture().get_image())

func close_freeze() -> void:
	$Transition/Freeze.hide()
	$Transition.hide()

var recording_dir = config_path.path_join("marathon_recordings")

func update_game_status() -> void:
	var lives_str := str(Global.lives)
	if Settings.file.difficulty.inf_lives == 1:
		lives_str = "∞"
	var string := "Coins = " + str(Global.coins) + " Lives = " + lives_str

func open_marathon_results() -> void:
	get_node("GameHUD/MarathonResults").open()

func open_disco_results() -> void:
	get_node("GameHUD/DiscoResults").open()

func on_score_sfx_finished() -> void:
	if tallying_score:
		$ScoreTally.play()

func get_server_version() -> void:
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(version_got)
	http.request(VERSION_CHECK_URL, [], HTTPClient.METHOD_GET)

func version_got(_result, response_code, _headers, body) -> void:
	if response_code == 200:
		server_version = int(body.get_string_from_utf8())
	else:
		server_version = -2

var error_log_cooldown := false

func log_error(msg := "", can_spam := true) -> void:
	if error_log_cooldown and not can_spam:
		return
	var error_message = $CanvasLayer/VBoxContainer/ErrorMessage.duplicate()
	error_message.text = "Error - " + msg
	error_message.visible = true
	if can_spam == false:
		do_cooldown()
	$CanvasLayer/VBoxContainer.add_child(error_message)
	await get_tree().create_timer(10, false).timeout
	error_message.queue_free()

func do_cooldown() -> void:
	error_log_cooldown = true
	await get_tree().create_timer(1, false).timeout
	error_log_cooldown = false

func log_warning(msg := "") -> void:
	var error_message: Label = $CanvasLayer/VBoxContainer/Warning.duplicate()
	error_message.text = "Warning - " + msg
	error_message.visible = true
	$CanvasLayer/VBoxContainer.add_child(error_message)
	await get_tree().create_timer(10, false).timeout
	error_message.queue_free()
	
func log_comment(msg := "") -> void:
	var error_message = $CanvasLayer/VBoxContainer/Comment.duplicate()
	error_message.text =  msg
	error_message.visible = true
	$CanvasLayer/VBoxContainer.add_child(error_message)
	await get_tree().create_timer(2, false).timeout
	error_message.queue_free()

func level_editor_is_playtesting() -> bool:
	if Global.level_editor == null:
		return false
	if Global.current_game_mode == Global.GameMode.LEVEL_EDITOR:
		if Global.level_editor.current_state == LevelEditor.EditorState.PLAYTESTING:
			return true
	return false

func unlock_achievement(achievement_id := AchievementID.SMB1_CLEAR) -> void:
	achievements[achievement_id] = "1"
	if achievement_id != AchievementID.COMPLETIONIST:
		check_completionist_achievement()
	SaveManager.write_achievements()

func check_completionist_achievement() -> void:
	if achievements.count("0") == 1:
		unlock_achievement(AchievementID.COMPLETIONIST)

const FONT = preload("res://Assets/Sprites/UI/Font.fnt")

func sanitize_string(string := "") -> String:
	string = string.to_upper()
	for i in string.length():
		if FONT.has_char(string.unicode_at(i)) == false and string[i] != "\n":
			string = string.replace(string[i], " ")
	return string

func get_base_asset_version() -> int:
	var json = JSON.parse_string(FileAccess.open("user://BaseAssets/pack_info.json", FileAccess.READ).get_as_text())
	var version = json.version
	return get_version_num_int(version)

func get_version_num_int(ver_num := "0.0.0") -> int:
	return int(ver_num.replace(".", ""))

func load_default_translations() -> void:
	for i in lang_codes:
		create_translation_from_json(i, "res://Assets/Locale/" + i + ".json")
	create_gal_translation("res://Assets/Locale/en.json")

func create_translation_from_json(locale := "", json_path := "") -> void:
	var trans = Translation.new()
	trans.locale = locale
	json_path = ResourceGetter.new().get_resource_path(json_path)
	var file = FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		return
	var json = JSON.parse_string(file.get_as_text())
	for i in json.keys():
		var value = json[i]
		if value is Dictionary:
			value = $ResourceSetterNew.get_variation_json(value).source
		trans.add_message(i, value.to_upper())
	if TranslationServer.get_translation_object(locale) != null:
		TranslationServer.remove_translation(TranslationServer.get_translation_object(locale))
	TranslationServer.add_translation(trans)

func create_gal_translation(en_json_path := "") -> void:
	var en_json = JSON.parse_string(FileAccess.open(en_json_path, FileAccess.READ).get_as_text())
	var translation = Translation.new()
	for i in en_json.keys():
		translation.add_message(i, convert_en_to_gal(en_json[i]))
	translation.locale = "gal"
	if TranslationServer.get_translation_object("gal") != null:
		TranslationServer.remove_translation(TranslationServer.get_translation_object("gal"))
	TranslationServer.add_translation(translation)

func convert_en_to_gal(en_string := "") -> String:
	var gal_string = en_string.to_upper()
	var idx := 0
	for i in gal_string:
		if gal_string[idx] in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
			gal_string[idx] = String.chr(i.unicode_at(0) + 65248)
		idx += 1
	return gal_string

func in_custom_campaign(campaign := current_custom_campaign) -> bool:
	return current_custom_campaign != ""
