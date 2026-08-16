extends Control

@export var room_color: Color = Color(0.15, 0.45, 0.8, 1.0)
@export var wall_color: Color = Color(1.0, 1.0, 1.0, 1.0) # Solid white outlines
@export var door_color: Color = Color(1.0, 0.3, 0.3, 1.0) # Red markers for thresholds
@export var player_color: Color = Color(0.2, 1.0, 0.2, 1.0) # Bright green flash tracker

var map_font: Font = ThemeDB.fallback_font # Engine default font for text drawing

func _ready():
	GameManager.map_updated.connect(queue_redraw)

func _draw():
	var cell_w = GameManager.CELL_SIZE.x
	var cell_h = GameManager.CELL_SIZE.y
	
	var center_offset = Vector2(
		-GameManager.current_room_coords.x * cell_w,
		-GameManager.current_room_coords.y * cell_h
	)
	
	# Loop through all coordinates registered in map registry
	for coords in GameManager.explored_rooms.keys():
		var data = GameManager.explored_rooms[coords]
		var origin = Vector2(coords.x * cell_w, coords.y * cell_h) + center_offset
		
		# A. Draw the filled room base
		var base_rect = Rect2(origin + Vector2(1,1), GameManager.CELL_SIZE - Vector2(2,2))
		draw_rect(base_rect, room_color, true)
		
		# B. Write Save Room Marker Icon text
		if data["is_save_room"]:
			var text_pos = origin + Vector2(cell_w / 2 - 4, cell_h / 2 + 6)
			draw_string(map_font, text_pos, "S", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
			
		# C. Calculate and draw precise boundary borders
		var borders = data["borders"]
		draw_border_segment(origin, origin + Vector2(cell_w, 0), borders["top"])       # Top Line
		draw_border_segment(origin + Vector2(0, cell_h), origin + Vector2(cell_w, cell_h), borders["bottom"]) # Bottom Line
		draw_border_segment(origin, origin + Vector2(0, cell_h), borders["left"])      # Left Line
		draw_border_segment(origin + Vector2(cell_w, 0), origin + Vector2(cell_w, cell_h), borders["right"])    # Right Line

	# D. Highlight current localized player slot
	var p_origin = Vector2(GameManager.current_room_coords.x * cell_w, GameManager.current_room_coords.y * cell_h) + center_offset
	var p_rect = Rect2(p_origin + (GameManager.CELL_SIZE / 3), GameManager.CELL_SIZE / 3)
	draw_rect(p_rect, player_color, true)

func draw_border_segment(p1: Vector2, p2: Vector2, type: String):
	match type:
		"Wall":
			draw_line(p1, p2, wall_color, 2.5)
		"Door":
			# Draw wall endpoints but leave a gap, filled with a colorful door dot line
			var mid_point = p1.lerp(p2, 0.5)
			draw_line(p1, p1.lerp(p2, 0.3), wall_color, 2.5)
			draw_line(mid_point - (mid_point - p1)*0.2, mid_point + (mid_point - p1)*0.2, door_color, 4.0)
			draw_line(p1.lerp(p2, 0.7), p2, wall_color, 2.5)
		"None":
			pass # Keep connection wide open
