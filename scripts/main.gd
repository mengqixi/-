extends Node2D

enum State { MENU, PLAYING, PAUSED, DEAD, CLEAR }
const LEVEL := preload("res://scenes/levels/level_01.tscn")
const BACKGROUND := preload("res://scripts/background.gd")
const SFX := preload("res://scripts/sfx.gd")
const FONT := preload("res://assets/fonts/AdventureSans.ttf")
const GODOT_LICENSE := "res://assets/licenses/Godot-LICENSE.txt"
const GODOT_NOTICES := "res://assets/licenses/Godot-COPYRIGHT.txt"
const FONT_LICENSE := "res://assets/licenses/NotoSansSC-OFL.txt"
var state := State.MENU
var level: Node2D
var background: Node2D
var sfx: Node
var ui: CanvasLayer
var hud: Panel
var coin_label: Label
var progress_fill: ColorRect
var help_label: Label
var shade: ColorRect
var overlay: Panel
var credits: Panel
var primary_button: Button
var theme: Theme
var coin_count := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_configure_inputs()
	var backdrop := CanvasLayer.new()
	backdrop.layer = -10
	add_child(backdrop)
	background = Node2D.new()
	background.set_script(BACKGROUND)
	backdrop.add_child(background)
	sfx = Node.new()
	sfx.set_script(SFX)
	add_child(sfx)
	_build_ui()
	_load_level()
	_show_menu()

func _configure_inputs() -> void:
	var bindings := {"move_left":[KEY_A,KEY_LEFT], "move_right":[KEY_D,KEY_RIGHT], "jump":[KEY_SPACE,KEY_W,KEY_UP], "pause_game":[KEY_ESCAPE], "confirm_game":[KEY_ENTER,KEY_KP_ENTER], "mute_game":[KEY_M]}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action,event)

func _load_level() -> void:
	get_tree().paused = false
	if is_instance_valid(level):
		remove_child(level)
		level.queue_free()
	level = LEVEL.instantiate()
	add_child(level)
	coin_count = 0
	coin_label.text = "金币  0 / %d" % level.total_coins()
	progress_fill.size.x = 0
	level.coin_collected.connect(_on_coin)
	level.player_died.connect(_on_death)
	level.level_completed.connect(_on_clear)
	level.sound_requested.connect(sfx.play_sound)

func start_game() -> void:
	_load_level()
	state = State.PLAYING
	level.show()
	background.menu_mode = false
	level.set_running(true)
	_hide_overlay()
	hud.show()
	help_label.show()

func _show_menu() -> void:
	state = State.MENU
	get_tree().paused = false
	level.set_running(false)
	level.hide()
	background.menu_mode = true
	hud.hide()
	help_label.hide()
	_show_menu_overlay()

func _show_menu_overlay() -> void:
	if is_instance_valid(overlay):
		ui.remove_child(overlay)
		overlay.queue_free()
	shade.hide()
	overlay = _panel(Vector2.ZERO,Vector2(360,216),Color(0,0,0,0))
	overlay.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	ui.add_child(overlay)
	var tag := _label(overlay,"RY'S ADVENTURE  /  01",Vector2(35,15),Vector2(290,17),10)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_color_override("font_color",Color("25565b"))
	var title := _label(overlay,"ry马里奥之旅",Vector2(5,36),Vector2(350,44),28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color",Color("fff2b4"))
	title.add_theme_color_override("font_outline_color",Color("285b52"))
	title.add_theme_constant_override("outline_size",4)
	title.add_theme_color_override("font_shadow_color",Color("408763"))
	title.add_theme_constant_override("shadow_offset_y",3)
	var subtitle := _label(overlay,"顶方块 · 吃蘑菇 · 踩怪 · 到达旗帜",Vector2(20,80),Vector2(320,17),10)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color",Color("25565b"))
	var card := _panel(Vector2(93,99),Vector2(174,88),Color("193968"))
	card.add_theme_stylebox_override("panel",_pixel_panel())
	overlay.add_child(card)
	primary_button = _button(card,"开始冒险  →",Vector2(12,12),Vector2(150,28))
	primary_button.pressed.connect(start_game)
	var exit_button := _button(card,"退出",Vector2(12,50),Vector2(71,26))
	exit_button.add_theme_font_size_override("font_size",9)
	exit_button.pressed.connect(func(): get_tree().quit())
	var about_button := _button(card,"制作信息",Vector2(91,50),Vector2(71,26))
	about_button.add_theme_font_size_override("font_size",9)
	about_button.pressed.connect(func(): credits.show(); ui.move_child(credits,ui.get_child_count()-1))
	var hero: CharacterBody2D = preload("res://scenes/player.tscn").instantiate()
	hero.position = Vector2(50,183)
	hero.scale = Vector2(2.6,2.6)
	hero.collision_layer = 0
	hero.collision_mask = 0
	overlay.add_child(hero)
	var monster: CharacterBody2D = preload("res://scenes/enemy.tscn").instantiate()
	monster.position = Vector2(309,183)
	monster.scale = Vector2(2.4,2.4)
	monster.collision_layer = 0
	monster.collision_mask = 0
	overlay.add_child(monster)
	monster.set_physics_process(false)
	var keys := _label(overlay,"A / D 或 ← → 移动    W / ↑ / 空格 二段跳",Vector2(5,193),Vector2(350,16),8)
	keys.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	keys.add_theme_color_override("font_color",Color("fff8e5"))
	keys.add_theme_color_override("font_outline_color",Color("2d6249"))
	keys.add_theme_constant_override("outline_size",2)
	primary_button.grab_focus()

func _on_coin() -> void:
	if state != State.PLAYING:
		return
	coin_count += 1
	coin_label.text = "金币  %d / %d" % [coin_count,level.total_coins()]

func _on_death(reason: String) -> void:
	if state != State.PLAYING:
		return
	state = State.DEAD
	_show_overlay("再试一次!", reason, "金币 %d / %d\n每次重试都是新的开始" % [coin_count,level.total_coins()], "重新挑战", start_game, "返回开始", _return_menu)

func _on_clear() -> void:
	if state != State.PLAYING:
		return
	state = State.CLEAR
	var all_coins: bool = coin_count == level.total_coins()
	_show_overlay("完美通关!" if all_coins else "通关成功!", "你到达了草地的终点", "金币 %d / %d    用时 %.1f 秒\n%s" % [coin_count,level.total_coins(),level.elapsed,"每一枚金币都被你找到了!" if all_coins else "再玩一次，试试找到所有金币!"], "再玩一次", start_game, "返回开始", _return_menu)

func _return_menu() -> void:
	_load_level()
	_show_menu()

func pause_game() -> void:
	if state != State.PLAYING:
		return
	state = State.PAUSED
	get_tree().paused = true
	_show_overlay("休息一下", "游戏已暂停", "Esc 继续游戏\nM 切换声音", "继续冒险", resume_game, "返回开始", _return_menu)

func resume_game() -> void:
	if state != State.PAUSED:
		return
	get_tree().paused = false
	state = State.PLAYING
	_hide_overlay()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		if credits.visible:
			credits.hide()
		elif state == State.PLAYING:
			pause_game()
		elif state == State.PAUSED:
			resume_game()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm_game") and not credits.visible:
		if state in [State.MENU,State.DEAD,State.CLEAR]:
			start_game()
		elif state == State.PAUSED:
			resume_game()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("mute_game"):
		sfx.muted = not sfx.muted
		help_label.text = "W / ↑ / 空格 二段跳    Esc 暂停    M 声音" + (" [关]" if sfx.muted else " [开]")

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == State.PLAYING:
		pause_game()

func _process(_delta: float) -> void:
	if is_instance_valid(level) and is_instance_valid(level.camera):
		background.scroll = level.camera.position.x - 180.0
		progress_fill.size.x = level.distance_ratio * 326.0
	background.set_process(state != State.PAUSED)

func _build_ui() -> void:
	theme = Theme.new()
	theme.default_font = FONT
	theme.default_font_size = 11
	theme.set_color("font_color","Label",Color("fff0ce"))
	theme.set_color("font_color","Button",Color("fff5d9"))
	theme.set_color("font_hover_color","Button",Color("ffffff"))
	theme.set_color("font_pressed_color","Button",Color("fff5d9"))
	theme.set_stylebox("normal","Button",_style(Color("d6583e"),Color("7f322b"),0))
	theme.set_stylebox("hover","Button",_style(Color("ef7950"),Color("ffe69a"),0))
	theme.set_stylebox("pressed","Button",_style(Color("b13e30"),Color("733126"),0))
	theme.set_stylebox("focus","Button",_style(Color(0,0,0,0),Color("f6db79"),0))
	ui = CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	hud = _panel(Vector2(8,7),Vector2(344,27),Color("fff5dd"))
	hud.add_theme_stylebox_override("panel",_style(Color("fff5dd"),Color("46744d"),3))
	ui.add_child(hud)
	var level_label := _label(hud,"WORLD 1-1 · 草地初体验",Vector2(9,3),Vector2(220,15),9)
	level_label.add_theme_color_override("font_color",Color("35583e"))
	coin_label = _label(hud,"金币 0 / 12",Vector2(244,3),Vector2(90,15),10)
	coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	coin_label.add_theme_color_override("font_color",Color("8b622c"))
	var progress_track := ColorRect.new()
	progress_track.position = Vector2(9,21)
	progress_track.size = Vector2(326,3)
	progress_track.color = Color("e6dcc1")
	progress_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(progress_track)
	progress_fill = ColorRect.new()
	progress_fill.size = Vector2(0,3)
	progress_fill.color = Color("6aab57")
	progress_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_track.add_child(progress_fill)
	help_label = _label(ui,"W / ↑ / 空格 二段跳    Esc 暂停    M 声音 [开]",Vector2(8,201),Vector2(344,13),8)
	help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help_label.add_theme_color_override("font_shadow_color",Color("234448"))
	help_label.add_theme_constant_override("shadow_offset_x",1)
	help_label.add_theme_constant_override("shadow_offset_y",1)
	shade = ColorRect.new()
	shade.position = Vector2.ZERO
	shade.size = Vector2(360,216)
	shade.color = Color(0.05,0.14,0.16,0.42)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	ui.add_child(shade)
	credits = _panel(Vector2(20,12),Vector2(320,192),Color("233d41"))
	ui.add_child(credits)
	_label(credits,"制作信息与许可",Vector2(12,8),Vector2(290,20),15)
	var text := RichTextLabel.new()
	text.position = Vector2(12,34)
	text.size = Vector2(296,119)
	text.theme = theme
	text.add_theme_font_size_override("normal_font_size",8)
	text.text = "ry马里奥之旅 v1.0\n玩法参考经典横版平台游戏。图标和怪物头像照片由用户提供；关卡、其余像素画面和音效为本项目原创。AI 协助完成设计、编码与验证。\n单文件程序，全部场景、字体和许可均内嵌。\n\nGodot Engine 4.7.2\n" + FileAccess.get_file_as_string(GODOT_LICENSE) + "\n\nGodot 第三方声明\n" + FileAccess.get_file_as_string(GODOT_NOTICES) + "\n\nNoto Sans SC 字体\n" + FileAccess.get_file_as_string(FONT_LICENSE)
	credits.add_child(text)
	var close := _button(credits,"返回",Vector2(102,161),Vector2(116,23))
	close.pressed.connect(func(): credits.hide(); primary_button.grab_focus())
	credits.hide()

func _show_overlay(title: String, subtitle: String, description: String, primary: String, primary_action: Callable, secondary: String, secondary_action: Callable) -> void:
	if is_instance_valid(overlay):
		ui.remove_child(overlay)
		overlay.queue_free()
	shade.show()
	overlay = _panel(Vector2(59,29),Vector2(242,158),Color("193968"))
	overlay.add_theme_stylebox_override("panel",_pixel_panel())
	ui.add_child(overlay)
	var art := Node2D.new()
	art.set_script(preload("res://scripts/ui_art.gd"))
	overlay.add_child(art)
	var tag := _label(overlay,"STAGE CLEAR" if state == State.CLEAR else ("PAUSED" if state == State.PAUSED else "TRY AGAIN"),Vector2(10,9),Vector2(222,16),9)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_color_override("font_color",Color("9bc0ef"))
	var heading := _label(overlay,title,Vector2(12,32),Vector2(218,28),22)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color",Color("ffdc79"))
	heading.add_theme_color_override("font_shadow_color",Color("102544"))
	heading.add_theme_constant_override("shadow_offset_y",2)
	var sub := _label(overlay,subtitle,Vector2(12,65),Vector2(218,15),9)
	sub.add_theme_color_override("font_color",Color("fff0c6"))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var detail := _label(overlay,description,Vector2(12,83),Vector2(218,29),9)
	detail.add_theme_color_override("font_color",Color("aacae5"))
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	primary_button = _button(overlay,primary,Vector2(20,121),Vector2(93,26))
	primary_button.pressed.connect(primary_action)
	var second := _button(overlay,secondary,Vector2(129,121),Vector2(93,26))
	second.add_theme_font_size_override("font_size",9)
	second.pressed.connect(secondary_action)
	primary_button.grab_focus()

func _hide_overlay() -> void:
	shade.hide()
	credits.hide()
	if is_instance_valid(overlay):
		overlay.hide()
	get_viewport().gui_release_focus()

func _style(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	box.content_margin_top = 2
	box.content_margin_bottom = 2
	box.content_margin_left = 4
	box.content_margin_right = 4
	return box

func _pixel_panel() -> StyleBoxFlat:
	var box := _style(Color("193968"),Color("f1ce77"),0)
	box.set_border_width_all(2)
	box.shadow_color = Color(0.03,0.08,0.16,0.6)
	box.shadow_size = 2
	box.shadow_offset = Vector2(3,3)
	return box

func _panel(at: Vector2, dimensions: Vector2, color: Color) -> Panel:
	var panel := Panel.new()
	panel.position = at
	panel.size = dimensions
	panel.theme = theme
	panel.add_theme_stylebox_override("panel",_style(color,Color("557e70"),5))
	return panel

func _label(parent: Node, text: String, at: Vector2, dimensions: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.theme = theme
	label.text = text
	label.position = at
	label.size = dimensions
	label.add_theme_font_size_override("font_size",font_size)
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, at: Vector2, dimensions: Vector2) -> Button:
	var button := Button.new()
	button.theme = theme
	button.add_theme_font_size_override("font_size",10)
	button.text = text
	button.position = at
	button.size = dimensions
	parent.add_child(button)
	# The initial off-tree default font can grow the button before our theme resolves.
	# Apply the intended dimensions after the theme's real minimum has settled.
	button.set_deferred("size",dimensions)
	return button
