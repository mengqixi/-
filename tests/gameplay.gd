extends SceneTree

var game: Node
var results: Array[Dictionary] = []
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _step(count: int = 1) -> void:
	for _i in range(count):
		await process_frame

func _check(condition: bool, label: String) -> void:
	results.append({"check":label,"passed":condition})
	print(("PASS " if condition else "FAIL ") + label)
	if not condition:
		failures += 1

func _restart() -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("jump")
	game.start_game()
	await _step(5)

func _jump_height(hold_frames: int) -> float:
	await _restart()
	Input.action_press("jump")
	var lowest := 180.0
	for i in range(55):
		if i == hold_frames:
			Input.action_release("jump")
		await _step()
		lowest = minf(lowest,game.level.player.position.y)
	Input.action_release("jump")
	return 180.0-lowest

func _run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await _step(3)
	_check(game.state == game.State.MENU,"starts at menu")
	for key in [KEY_SPACE,KEY_W,KEY_UP]:
		var found := false
		for event in InputMap.action_get_events("jump"):
			if event is InputEventKey and event.physical_keycode == key:
				found = true
		_check(found,"jump binding %d" % key)
	for key in [KEY_SPACE,KEY_W,KEY_UP]:
		await _restart()
		var key_event := InputEventKey.new()
		key_event.physical_keycode = key
		key_event.pressed = true
		Input.parse_input_event(key_event)
		await _step(5)
		_check(game.level.player.position.y < 175.0,"physical jump key %d works" % key)
		key_event = InputEventKey.new()
		key_event.physical_keycode = key
		key_event.pressed = false
		Input.parse_input_event(key_event)
		await _step(2)
	for binding in [[KEY_A,-1.0],[KEY_LEFT,-1.0],[KEY_D,1.0],[KEY_RIGHT,1.0]]:
		await _restart()
		var movement_event := InputEventKey.new()
		movement_event.physical_keycode = binding[0]
		movement_event.pressed = true
		Input.parse_input_event(movement_event)
		await _step(15)
		_check((game.level.player.position.x-63.0)*binding[1] > 10.0,"physical move key %d works" % binding[0])
		movement_event = InputEventKey.new()
		movement_event.physical_keycode = binding[0]
		movement_event.pressed = false
		Input.parse_input_event(movement_event)
		await _step(2)
	var full_height := await _jump_height(40)
	var short_height := await _jump_height(2)
	_check(full_height > 45.0 and short_height < full_height-15.0,"short and held jumps differ")
	await _restart()
	Input.action_press("jump")
	await _step(10)
	Input.action_release("jump")
	await _step(2)
	Input.action_press("jump")
	await _step(1)
	_check(game.level.player.jumps_used == 2 and game.level.player.velocity.y < -240,"second jump works in midair")
	Input.action_release("jump")
	await _step(2)
	var velocity_after_second: float = game.level.player.velocity.y
	Input.action_press("jump")
	await _step(1)
	_check(game.level.player.jumps_used == 2 and game.level.player.velocity.y >= velocity_after_second,"third midair jump is blocked")
	Input.action_release("jump")
	await _step(80)
	_check(game.level.player.is_on_floor() and game.level.player.jumps_used == 0,"landing resets double jump")
	await _restart()
	game.level.player.position = Vector2(495,100)
	await _step(25)
	_check(game.level.player.is_on_floor() and absf(game.level.player.position.y-126)<0.2,"player can stand on upper brick platform")
	Input.action_press("move_right")
	await _step(12)
	Input.action_release("move_right")
	_check(game.level.player.position.x > 505 and absf(game.level.player.position.y-126)<0.2,"player can walk along upper platform")
	await _restart()
	await _step(20)
	_check(absf(game.level.enemies[2].position.y-126)<0.2,"enemy patrols on elevated platform")
	await _restart()
	Input.action_press("move_right")
	await _step(60)
	Input.action_release("move_right")
	_check(game.level.player.position.x > 160.0,"keyboard movement advances player")
	await _restart()
	var enemy: CharacterBody2D = game.level.enemies[0]
	game.level.player.position = enemy.position + Vector2(-12,0)
	await _step(2)
	_check(game.state == game.State.DEAD,"side contact causes death")
	await _restart()
	enemy = game.level.enemies[0]
	game.level.player.position = enemy.position + Vector2(0,10)
	await _step(2)
	_check(game.state == game.State.DEAD,"contact from below causes death")
	await _restart()
	enemy = game.level.enemies[0]
	enemy.position = Vector2(405,180)
	game.level.player.position = enemy.position + Vector2(0,-40)
	game.level.player.velocity = Vector2(0,180)
	await _step(7)
	_check(enemy.defeated and game.state == game.State.PLAYING and game.level.player.velocity.y < 0,"descending stomp defeats enemy and bounces")
	for pit_x in [585.0,1431.0]:
		await _restart()
		game.level.player.position = Vector2(pit_x,180)
		await _step(60)
		_check(game.state == game.State.DEAD,"pit death at %.0f" % pit_x)
	await _restart()
	# Hit the first question block with a real upward jump, not a direct reward call.
	game.level.player.position = Vector2(207,180)
	await _step(3)
	Input.action_press("jump")
	await _step(35)
	Input.action_release("jump")
	_check(game.level.lucky_blocks[0].used and game.coin_count == 1,"head bump releases one hidden coin")
	game.level.lucky_blocks[0].bump()
	_check(game.coin_count == 1,"used lucky block cannot reward twice")
	await _restart()
	game.level.player.position = Vector2(783,180)
	await _step(3)
	Input.action_press("jump")
	await _step(35)
	Input.action_release("jump")
	_check(game.level.lucky_blocks[1].used and game.level.mushrooms.size() == 1,"head bump spawns moving mushroom")
	var mushroom: CharacterBody2D = game.level.mushrooms[0]
	game.level.player.position = mushroom.position + Vector2(0,5)
	game.level.player.velocity = Vector2.ZERO
	await _step(5)
	_check(game.level.player.is_big and game.level.player.body_rect().size.y == 28,"mushroom pickup enlarges character and collision")
	game.level.player.position = game.level.enemies[0].position+Vector2(-12,0)
	await _step(2)
	_check(game.state == game.State.PLAYING and not game.level.player.is_big and game.level.player.invincible_time > 0,"big player shrinks with temporary protection")
	await _step(100)
	game.level.player.position = game.level.enemies[0].position+Vector2(-12,0)
	await _step(2)
	_check(game.state == game.State.DEAD,"small player dies after protection expires")
	await _restart()
	game.level.player.position = Vector2(207,142)
	game.level.player.grow()
	_check(not game.level.player.is_big and game.level.player.pending_growth,"growth waits when headroom is blocked")
	game.level.player.position = Vector2(260,180)
	await _step(3)
	_check(game.level.player.is_big,"pending growth applies in open space")
	await _restart()
	for coin in game.level.coins:
		game.level.player.position = coin.position + Vector2(0,7)
		game.level.player.velocity = Vector2.ZERO
		await _step(2)
	game.level.lucky_blocks[0].bump()
	_check(game.coin_count == 12,"all 12 coins can be collected")
	await _step(5)
	_check(game.coin_count == 12,"collected coins cannot count twice")
	game.level.player.position = game.level.goal.position + Vector2(-8,0)
	game.level.player.velocity = Vector2.ZERO
	await _step(2)
	_check(game.state == game.State.CLEAR and game.coin_count == 12,"all-coin clear result")
	await _restart()
	game.level.player.position = game.level.goal.position + Vector2(-8,0)
	await _step(2)
	_check(game.state == game.State.CLEAR and game.coin_count == 0,"zero-coin clear allowed")
	await _restart()
	game.level.enemies[0].position = game.level.goal.position
	game.level.player.position = game.level.goal.position
	await _step(2)
	_check(game.state == game.State.DEAD and not game.level.goal.triggered,"death takes priority over simultaneous goal")
	for i in range(5):
		await _restart()
		game.level.enemies[0].defeat()
		game.level.player.position = game.level.coins[0].position + Vector2(0,7)
		await _step(2)
		game.level.player.position.y = 250
		await _step(2)
		await _restart()
		_check(game.coin_count == 0 and not game.level.enemies[0].defeated and not game.level.coins[0].taken and not game.level.lucky_blocks[0].used and not game.level.player.is_big,"complete retry reset %d" % (i+1))
	await _restart()
	game.pause_game()
	var frozen_position: Vector2 = game.level.player.position
	var frozen_time: float = game.level.elapsed
	Input.action_press("move_right")
	await _step(20)
	_check(game.level.player.position == frozen_position and game.level.elapsed == frozen_time,"pause freezes world and timer")
	game.resume_game()
	await _step(20)
	Input.action_release("move_right")
	_check(game.level.player.position.x > frozen_position.x,"resume restores movement")
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(game.state == game.State.PAUSED,"losing focus pauses gameplay")
	await _restart()
	# Traverse from spawn to flag using only the same movement/jump actions as a player.
	# Targeted contact tests above use positioned fixtures; this route does not teleport.
	Input.action_press("move_right")
	var route_frames := 0
	var jump_active := false
	while game.state == game.State.PLAYING and route_frames < 2400:
		var player: CharacterBody2D = game.level.player
		var should_jump := false
		if player.is_on_floor():
			for column in [18,51,103,104]:
				var distance: float = column*18-player.position.x
				if distance > 8.0 and distance < 34.0 and player.position.y > 147.0:
					should_jump = true
			for start_column in [32,79]:
				var distance: float = start_column*18-player.position.x
				if distance > 0.0 and distance < 13.0:
					should_jump = true
			for foe in game.level.enemies:
				if not foe.defeated and foe.position.x-player.position.x > 0.0 and foe.position.x-player.position.x < 40.0:
					should_jump = true
			if jump_active:
				Input.action_release("jump")
				jump_active = false
			elif should_jump:
				Input.action_press("jump")
				jump_active = true
		await _step()
		route_frames += 1
	Input.action_release("move_right")
	Input.action_release("jump")
	print("Route end: state=%s x=%.1f y=%.1f frames=%d" % [game.state,game.level.player.position.x,game.level.player.position.y,route_frames])
	_check(game.state == game.State.CLEAR,"full level traversable from spawn using inputs")
	var report := {"failures":failures,"checks":results,"full_jump_height":full_height,"short_jump_height":short_height,"route_frames":route_frames}
	var report_path: String = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "res://verification/gameplay-results.json"
	var file := FileAccess.open(report_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	file.close()
	print("TEST RESULT: %d checks, %d failures" % [results.size(),failures])
	game.queue_free()
	await _step(5)
	# Audio mixing is real-time even with --fixed-fps; let queued playback cleanup run.
	OS.delay_msec(100)
	quit(0 if failures == 0 else 1)
