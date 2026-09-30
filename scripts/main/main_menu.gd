extends Control

func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color("#080d16")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var title := Label.new()
	title.text = "THE GROTTO"
	title.position = Vector2(90, 120)
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color("#9ad9d1"))
	add_child(title)
	var subtitle := Label.new()
	subtitle.text = "A dark descent shaped by music"
	subtitle.position = Vector2(94, 190)
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color("#8190a8"))
	add_child(subtitle)
	var play := Button.new()
	play.text = "PLAY"
	play.position = Vector2(94, 280)
	play.size = Vector2(230, 52)
	play.pressed.connect(_enter_grotto)
	add_child(play)
	var quit := Button.new()
	quit.text = "QUIT"
	quit.position = Vector2(94, 344)
	quit.size = Vector2(230, 52)
	quit.pressed.connect(_quit_game)
	add_child(quit)
	var note := Label.new()
	note.text = "WASD / arrows move   •   Left click / Space attack   •   C dodge   •   E interact"
	note.position = Vector2(94, 445)
	note.add_theme_color_override("font_color", Color("#6e7b91"))
	add_child(note)

func _enter_grotto() -> void:
	print("PLAYTEST PLAY_PRESSED")
	get_tree().change_scene_to_file("res://scenes/grotto/grotto.tscn")

func _quit_game() -> void:
	get_tree().quit()
