extends Node

signal player_health_changed(current_health, max_health)
signal abilities_updated(unlocked_list)
signal map_updated 
signal game_saved
signal switch_toggled(switch_id: StringName, is_on: bool)

const CELL_SIZE = Vector2(32, 24) 
const SAVE_FILE_PATH = "user://savegame.dat" # Secure local file path

var target_door: TargetDoor = null
var explored_rooms: Dictionary = {}
var defeated_enemies: Array = []
var permanent_flags: Array = [] #like bosses and upgrades and shit, so they don´t respawn
var current_room_coords: Vector2i = Vector2i(0, 0)
var last_save_room_path: String = "" 

var switches: Dictionary[StringName, bool] = {}

var player_data := PlayerData.new(100, 100)

func discover_room(coords: Vector2i, room_data: Dictionary):
	current_room_coords = coords
	# Add or overwrite map structure info
	explored_rooms[coords] = room_data
	map_updated.emit()
		
func update_health(amount: int):
	player_data.health = clampi(player_data.health + amount, 0, player_data.max_health)
	player_health_changed.emit(player_data.health, player_data.max_health)
	if player_data.health <= 0:
		handle_player_death()

func update_max_health(amount: int):
	player_data.max_health += amount
	player_data.health += amount
	player_health_changed.emit(player_data.health, player_data.max_health)

func unlock_ability(ability_name: String):
	if not player_data.unlocked_abilities.has(ability_name):
		player_data.unlocked_abilities.append(ability_name)
		abilities_updated.emit(player_data.unlocked_abilities)

func save_game(room_path: String):
	last_save_room_path = room_path
	defeated_enemies.clear()
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		var save_dict = {
			"last_save_room_path": last_save_room_path,
			"player_data": player_data,
			"explored_rooms": explored_rooms,
			"permanent_flags": permanent_flags,
			"switches": switches,
		}
		
		var json_string = JSON.stringify(save_dict)
		file.store_line(json_string)
		file.close()
		
		game_saved.emit()
		print("Game saved.")

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		return false
		
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_line()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var save_data = json.get_data()
			
			last_save_room_path = save_data["last_save_room_path"]
			player_data = save_data["player_data"]
			permanent_flags = save_data["permanent_flags"]
			explored_rooms.clear()
			for str_key in save_data["explored_rooms"].keys():
				var coords = str_to_var("Vector2i" + str_key) # Rebuilds Vector2i structure
				explored_rooms[coords] = save_data["explored_rooms"][str_key]
			
			target_door = TargetDoor.new("SAVE_POINT")
			
			switches = save_data["switches"]
			
			get_tree().call_deferred("change_scene_to_file", last_save_room_path)
			return true
			
	return false

func reset_game():
	target_door = null
	current_room_coords = Vector2i(0,0)
	last_save_room_path = ""
	explored_rooms.clear()
	player_data = PlayerData.new(
		100,
		100,
	)
		
func respawn_player():
	player_data.health = player_data.max_health
	player_health_changed.emit(player_data.health, player_data.max_health)
	if last_save_room_path != "":
		target_door = TargetDoor.new("SAVE_POINT")
		get_tree().call_deferred("change_scene_to_file", last_save_room_path)
		
func handle_player_death():
	print("Game Over")
	get_tree().paused = true
	await get_tree().create_timer(1).timeout
	UiLayer.game_over_bg.show()
	
func transition_to_room(
	room_scene_path: String, 
	door_id: String, 
	door_offset: Vector3 = Vector3.ZERO,
	player: Player = null
):
	target_door = TargetDoor.new(door_id, door_offset, player)
	UiLayer.animation_player.play("fade_to_black")
	await UiLayer.animation_player.animation_finished
	get_tree().call_deferred("change_scene_to_file", room_scene_path)


func register_player(player_node: CharacterBody3D):
	var doors = get_tree().get_nodes_in_group("Exit")
	for door in doors:
		if door.door_id == target_door.door_id:
			player_node.global_position = door.get_spawn_position() + target_door.door_offset
			
			if not player_node is Player:
				return
			
			player_node.set_state(target_door.player_state)
			
			if target_door.player_state != Player.PlayerState.NORMAL:
				player_node.set_direction(target_door.player_direction)
				return
				
			if door.maintain_velocity:
				player_node.velocity = target_door.player_velocity
				player_node.set_direction(target_door.player_direction)
				
			if door.exit_velocity != Vector3.ZERO:
				player_node.disable_input_until_on_floor()
				
				var exit_velocity = door.exit_velocity
				
				if door.maintain_direction or door.maintain_velocity:
					if door.maintain_velocity and target_door.player_velocity.z > 0:
						exit_velocity.z = absf(exit_velocity.z)
					elif door.maintain_velocity and target_door.player_velocity.z < 0:
						exit_velocity.z = absf(exit_velocity.z) * -1
					elif target_door.player_direction == Player.PlayerDirection.LEFT:
						exit_velocity.z = absf(exit_velocity.z)
						player_node.set_direction(Player.PlayerDirection.LEFT)
					else:
						exit_velocity.z = absf(exit_velocity.z) * -1
						player_node.set_direction(Player.PlayerDirection.RIGHT)
				else:
					if exit_velocity.z > 0.0:
						player_node.set_direction(Player.PlayerDirection.LEFT)
					elif exit_velocity.z < 0.0:
						player_node.set_direction(Player.PlayerDirection.RIGHT)
					else:
						player_node.set_direction(target_door.player_direction)
						
				player_node.velocity += exit_velocity
			elif not door.maintain_velocity:
				player_node.set_direction(target_door.player_direction)
				
			return
			
	print("Warning: No matching door found for ID: ", target_door.door_id)
	

func toggle_switch(switch_id: StringName, is_on: bool):
	if switches.has(switch_id) and switches[switch_id] == is_on:
		return
		
	switches[switch_id] = is_on
	switch_toggled.emit(switch_id, is_on)

'''
slop response regarding save/load functionality on itch.io, will need to test later
1. How Godot Handles user:// 
on the WebWhen you export your game to HTML5/Web, the web browser restricts the game from 
accessing the player’s actual hard drive for security reasons.To solve this, Godot automatically
 maps the user:// path (which we used for user://savegame.dat) to a virtual file system called 
IndexedDB inside the web browser.When your script calls FileAccess.open("user://savegame.dat", 
FileAccess.WRITE), Godot writes the JSON string directly into the browser's local application 
storage.When the player comes back to your Itch.io page later, the browser re-links that 
IndexedDB storage, and your Continue button will work perfectly.

2. Mandatory Itch.io Export Settings
For the browser to keep track of the save file and not overwrite it, you must configure your 
Godot export profiles correctly.Go to Project > Export in the Godot editor.
Click Add... at the top and select Web (HTML5).In the right-hand options panel, 
scroll down to the Options section and look for Vram Texture Compression. 
Ensure your textures are optimized for mobile/web.The Critical Setting: Look for Export Path / File Name. 
Ensure you give your game a unique name. Do not leave it as index.html or generic titles 
if you have multiple web games, as browsers partition IndexedDB space based on the page's exact 
URL path structure and name profile.

3. Important Web-Specific Limitations to keep in mind
While the code stays the same, web browsers introduce a few quirks you should design around:
	A. Private/Incognito Mode Wipes Saves
		If a player plays your game inside a Private Browsing or Incognito tab, 
		the web browser completely deletes the IndexedDB cache the exact millisecond they close the window.
		Your save game will be lost forever. It is helpful to put a small text note on
		 your Itch.io description page warning players about this.
	B. Browser Cookies and Cache Clearing
		If a player manually clears their browser cookies, browser history, or site cache, the browser
		 might wipe out the IndexedDB tables along with it.
	C. Itch.io Canvas "Run Game" Focus
		On web platforms, inputs (like pressing E to interact with a save station or using the arrow keys) 
		will not register until the user physically clicks inside the game container screen to give 
		the browser window operational focus.
'''
