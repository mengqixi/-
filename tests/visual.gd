extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _wait_frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _save(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var output_dir: String = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "res://verification"
	image.save_png(output_dir.path_join(name + ".png"))

func _capture() -> void:
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await _wait_frames(10)
	for child in game.primary_button.get_parent().get_children():
		if child is Button:
			print("BUTTON %s size=%s minimum=%s font=%d style=%s" % [child.text,child.size,child.get_combined_minimum_size(),child.get_theme_font_size("font_size"),child.get_theme_stylebox("normal").get_minimum_size()])
	await _save("menu")
	game.start_game()
	await _wait_frames(10)
	await _save("game-start")
	game.level.player.position = Vector2(207,180)
	await _wait_frames(3)
	Input.action_press("jump")
	await _wait_frames(14)
	Input.action_release("jump")
	await _save("lucky-block")
	game.pause_game()
	await _wait_frames(3)
	await _save("pause")
	game.resume_game()
	game.level.player.position = Vector2(948,140)
	game.level.player.velocity = Vector2.ZERO
	await _wait_frames(5)
	await _save("green-pipe")
	game.level.player.position = Vector2(820,180)
	game.level.player.grow()
	await _wait_frames(3)
	await _save("big-player")
	game.level.player.position = Vector2(1668,110)
	game.level.player.velocity = Vector2.ZERO
	await _wait_frames(7)
	await _save("upper-platform")
	game.level.player.position = game.level.goal.position+Vector2(-8,0)
	await _wait_frames(5)
	await _save("clear")
	game.queue_free()
	await _wait_frames(2)
	quit()
