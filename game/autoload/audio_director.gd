extends Node

var music_players: Array[AudioStreamPlayer] = []
var active_music := 0
var current_music_path := ""
var sfx_players: Array[AudioStreamPlayer] = []
var music_tween: Tween


func _ready() -> void:
	for _index in range(2):
		var player := AudioStreamPlayer.new()
		player.bus = &"Music"
		player.volume_db = -80.0
		add_child(player)
		music_players.append(player)
	for _index in range(10):
		var player := AudioStreamPlayer.new()
		player.bus = &"Effects"
		add_child(player)
		sfx_players.append(player)


func play_music(resource_path: String, fade_seconds: float = 1.2) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if resource_path == current_music_path or not ResourceLoader.exists(resource_path):
		return
	current_music_path = resource_path
	if music_tween and music_tween.is_valid():
		music_tween.kill()
	var old_player: AudioStreamPlayer = music_players[active_music]
	active_music = 1 - active_music
	var new_player: AudioStreamPlayer = music_players[active_music]
	new_player.stream = load(resource_path)
	new_player.volume_db = -60.0
	new_player.play()
	music_tween = create_tween().set_parallel(true)
	music_tween.tween_property(old_player, "volume_db", -60.0, fade_seconds)
	music_tween.tween_property(new_player, "volume_db", 0.0, fade_seconds)
	music_tween.chain().tween_callback(old_player.stop)


func play_sfx(resource_path: String, pitch: float = 1.0) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if not ResourceLoader.exists(resource_path):
		return
	var player: AudioStreamPlayer = sfx_players[0]
	for candidate: AudioStreamPlayer in sfx_players:
		if not candidate.playing:
			player = candidate
			break
	player.stream = load(resource_path)
	player.pitch_scale = clampf(pitch, 0.7, 1.35)
	player.play()


func stop_all() -> void:
	if music_tween and music_tween.is_valid():
		music_tween.kill()
	for player: AudioStreamPlayer in music_players + sfx_players:
		player.stop()
		player.stream = null
	current_music_path = ""
