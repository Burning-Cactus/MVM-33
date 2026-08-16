extends Node

@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var sfx: Node = $SFX

func play_music(track:AudioStream):
	music_player.stream = track
	music_player.bus = "MUSIC"
	
func play_sfx(audio: AudioStream, single=false,randomize_pitch=false):
	if not audio:
		return
		
	if single:
		stop_sfx()

	for player: AudioStreamPlayer in sfx.get_children():
		if not player.playing:
			player.stream = audio
			player.bus = "BUS"
			if randomize_pitch:
				player.pitch_scale = randf_range(0.8,1.1)
			player.play()
			break

func stop_sfx():
	for player: AudioStreamPlayer in sfx.get_children():
		player.stop()
