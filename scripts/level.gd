extends Node2D

signal coin_collected
signal player_died(reason: String)
signal level_completed
signal sound_requested(sound_name: String)

const PLAYER := preload("res://scenes/player.tscn")
const ENEMY := preload("res://scenes/enemy.tscn")
const COIN := preload("res://scenes/coin.tscn")
const GOAL := preload("res://scenes/goal.tscn")
const LUCKY := preload("res://scenes/lucky_block.tscn")
const MUSHROOM := preload("res://scenes/mushroom.tscn")
const FONT := preload("res://assets/fonts/AdventureSans.ttf")
const TILE := 18
@export var level_name := "第一关 · 草地初体验"
@export var width_tiles := 120
@export var pit_columns := PackedInt32Array([32, 33, 79, 80, 81])
@export var obstacle_columns := PackedInt32Array([18, 51, 52, 103, 104, 105])
@export var obstacle_heights := PackedInt32Array([1, 2, 2, 1, 2, 1])
@export var coin_columns := PackedInt32Array([10, 20, 28, 32, 44, 55, 66, 79, 90, 105, 113])
@export var coin_y_positions := PackedInt32Array([153, 135, 153, 135, 153, 135, 135, 135, 153, 117, 153])
@export var enemy_patrols := PackedVector2Array([Vector2(22,27), Vector2(60,68), Vector2(91,97)])
@export var platform_segments := PackedVector3Array([Vector3(26,29,7),Vector3(58,69,6),Vector3(89,99,7)])
@export var elevated_enemy := Vector2(91,97)
var player: CharacterBody2D
var camera: Camera2D
var goal: Node2D
var terrain: TileMapLayer
var enemies: Array[CharacterBody2D] = []
var coins: Array[Node2D] = []
var lucky_blocks: Array[StaticBody2D] = []
var mushrooms: Array[CharacterBody2D] = []
var particles: Array[Dictionary] = []
var running := false
var ended := false
var collected_count := 0
var elapsed := 0.0
var distance_ratio := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	process_physics_priority = 20
	_build_terrain()
	player = PLAYER.instantiate()
	player.position = Vector2(63, 180)
	player.z_index = 3
	add_child(player)
	player.jumped.connect(func(): sound_requested.emit("jump"))
	for patrol in enemy_patrols:
		var enemy: CharacterBody2D = ENEMY.instantiate()
		enemy.left_edge = (patrol.x + 0.5) * TILE
		enemy.right_edge = (patrol.y + 0.5) * TILE
		enemy.position = Vector2(enemy.right_edge,126 if patrol == elevated_enemy else 180)
		enemy.z_index = 3
		add_child(enemy)
		enemies.append(enemy)
	for i in range(coin_columns.size()):
		var coin: Node2D = COIN.instantiate()
		coin.position = Vector2((coin_columns[i] + 0.5) * TILE, coin_y_positions[i])
		coin.z_index = 3
		add_child(coin)
		coins.append(coin)
	goal = GOAL.instantiate()
	goal.position = Vector2((width_tiles - 2.5) * TILE, 180)
	goal.z_index = 4
	add_child(goal)
	for column in [11,43]:
		var block: StaticBody2D = LUCKY.instantiate()
		block.position = Vector2((column+0.5)*TILE,6.5*TILE)
		block.z_index = 2
		block.reward_type = "coin" if column == 11 else "mushroom"
		block.reward_released.connect(_on_block_reward.bind(block))
		add_child(block)
		lucky_blocks.append(block)
	camera = Camera2D.new()
	camera.position = Vector2(180, 108)
	add_child(camera)
	var scenery := Node2D.new()
	scenery.set_script(preload("res://scripts/scenery.gd"))
	scenery.z_index = 1
	add_child(scenery)
	set_running(false)
	queue_redraw()

func set_running(value: bool) -> void:
	running = value
	player.enabled = value
	for enemy in enemies:
		enemy.set_physics_process(value and not enemy.defeated)

func _physics_process(delta: float) -> void:
	if not running or ended:
		return
	elapsed += delta
	camera.position.x = clampf(player.position.x + 42.0, 180.0, width_tiles * TILE - 180.0)
	distance_ratio = clampf((player.position.x - 63.0) / (goal.position.x - 63.0), 0.0, 1.0)
	# All contact results are resolved here, after player and enemy movement.
	# A lethal contact wins over a goal contact in the same physics frame.
	var fatal := "掉入深坑"
	var dead := player.position.y > 240.0
	var player_rect: Rect2 = player.body_rect()
	for enemy in enemies:
		if enemy.defeated:
			continue
		var enemy_rect: Rect2 = enemy.body_rect()
		var horizontal_overlap := player_rect.end.x > enemy_rect.position.x and player_rect.position.x < enemy_rect.end.x
		var top := enemy_rect.position.y
		var previous_top: float = enemy.previous_position.y - enemy_rect.size.y
		var crossed_top: bool = horizontal_overlap and player.previous_velocity.y > 0.0 and player.previous_position.y <= previous_top + 2.0 and player.position.y >= top
		if crossed_top and player.position.y <= enemy_rect.end.y + 4.0:
			enemy.defeat()
			player.position.y = top
			player.bounce()
			_burst(enemy.position + Vector2(0,-7), Color("bd8daa"), "踩中!")
			sound_requested.emit("stomp")
			player_rect = player.body_rect()
		elif player_rect.intersects(enemy_rect):
			var was_big: bool = player.is_big
			if player.take_hit():
				dead = true
				fatal = "碰到怪物"
			elif was_big and not player.is_big:
				_burst(player.position+Vector2(0,-20),Color("f4c15a"),"变小了")
				sound_requested.emit("hurt")
	if dead:
		ended = true
		set_running(false)
		sound_requested.emit("death")
		player_died.emit(fatal)
		return
	for i in range(player.get_slide_collision_count()):
		var collision: KinematicCollision2D = player.get_slide_collision(i)
		var collider: Object = collision.get_collider()
		if collider is Node and collider.is_in_group("lucky_blocks") and collision.get_normal().y > 0.5 and player.previous_velocity.y < 0.0:
			collider.bump()
	for mushroom in mushrooms:
		if is_instance_valid(mushroom) and mushroom.try_collect(player_rect):
			player.grow()
			_burst(player.position+Vector2(0,-25),Color("ffda70"),"变大!")
			sound_requested.emit("grow")
	for coin in coins:
		if coin.try_collect(player_rect):
			collected_count += 1
			_burst(coin.position, Color("ffdb73"), "+1")
			sound_requested.emit("coin")
			coin_collected.emit()
	if goal.try_reach(player_rect):
		ended = true
		set_running(false)
		_burst(goal.position + Vector2(0,-42), Color("f6cf65"), "通关!")
		sound_requested.emit("clear")
		level_completed.emit()

func total_coins() -> int:
	return coin_columns.size()+1

func _on_block_reward(reward: String, block: StaticBody2D) -> void:
	if reward == "coin":
		collected_count += 1
		_burst(block.position+Vector2(0,-15),Color("ffdb73"),"+1")
		coin_collected.emit()
		sound_requested.emit("coin")
	else:
		var mushroom: CharacterBody2D = MUSHROOM.instantiate()
		mushroom.position = block.position+Vector2(0,-10)
		mushroom.z_index = 3
		add_child(mushroom)
		mushrooms.append(mushroom)
		sound_requested.emit("grow")

func _process(delta: float) -> void:
	var had_particles := not particles.is_empty()
	for particle in particles:
		particle["life"] -= delta
		particle["position"] += particle["velocity"] * delta
		particle["velocity"].y += 65.0 * delta
	particles = particles.filter(func(p): return p["life"] > 0.0)
	if had_particles:
		queue_redraw()

func _burst(at: Vector2, color: Color, text: String) -> void:
	for i in range(7):
		particles.append({"position":at, "velocity":Vector2((i-3)*13.0, -32.0-absf(i-3)*6.0), "life":0.55, "color":color, "text":""})
	particles.append({"position":at+Vector2(-7,-8), "velocity":Vector2(0,-22), "life":0.75, "color":Color("fff5d7"), "text":text})
	queue_redraw()

func _build_terrain() -> void:
	var image := Image.create(54, 18, false, Image.FORMAT_RGBA8)
	image.fill(Color("996b47"))
	for tile_id in range(3):
		var origin := tile_id * TILE
		image.fill_rect(Rect2i(origin,0,18,18), Color("aa7950") if tile_id < 2 else Color("b8895d"))
		image.fill_rect(Rect2i(origin,15,18,3), Color("875c42"))
		for y in [7,14]:
			image.fill_rect(Rect2i(origin,y,18,1), Color("96653f"))
		for x in [3,12]:
			image.fill_rect(Rect2i(origin+x,9,2,2), Color("c99363"))
		if tile_id == 0:
			image.fill_rect(Rect2i(origin,0,18,18),Color("472d26"))
			image.fill_rect(Rect2i(origin+1,1,16,16),Color("c77343"))
			image.fill_rect(Rect2i(origin+2,2,14,1),Color("f4bd8f"))
			image.fill_rect(Rect2i(origin+9,4,1,13),Color("89502e"))
			image.fill_rect(Rect2i(origin+1,9,16,1),Color("89502e"))
		if tile_id == 2:
			image.fill_rect(Rect2i(origin,0,18,18),Color("452d2d"))
			image.fill_rect(Rect2i(origin+1,1,16,16),Color("d07b4c"))
			image.fill_rect(Rect2i(origin+1,1,16,1),Color("f3b58a"))
			image.fill_rect(Rect2i(origin,8,18,1),Color("452d2d"))
			image.fill_rect(Rect2i(origin+8,0,1,8),Color("452d2d"))
			image.fill_rect(Rect2i(origin+3,9,1,9),Color("452d2d"))
	var atlas := TileSetAtlasSource.new()
	atlas.texture = ImageTexture.create_from_image(image)
	atlas.texture_region_size = Vector2i(TILE,TILE)
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(TILE,TILE)
	tiles.add_physics_layer()
	tiles.set_physics_layer_collision_layer(0,1)
	tiles.add_source(atlas, 0)
	for i in range(3):
		atlas.create_tile(Vector2i(i,0))
		var tile_data := atlas.get_tile_data(Vector2i(i,0),0)
		tile_data.set_collision_polygons_count(0,1)
		tile_data.set_collision_polygon_points(0,0,PackedVector2Array([Vector2(-9,-9),Vector2(9,-9),Vector2(9,9),Vector2(-9,9)]))
	terrain = TileMapLayer.new()
	terrain.tile_set = tiles
	add_child(terrain)
	for x in range(width_tiles):
		if x in pit_columns:
			continue
		terrain.set_cell(Vector2i(x,10),0,Vector2i(0,0))
		terrain.set_cell(Vector2i(x,11),0,Vector2i(1,0))
	for i in range(obstacle_columns.size()):
		for height in range(obstacle_heights[i]):
			terrain.set_cell(Vector2i(obstacle_columns[i],9-height),0,Vector2i(2,0))
	for x in [42]:
		terrain.set_cell(Vector2i(x,6),0,Vector2i(2,0))
	for segment in platform_segments:
		for x in range(int(segment.x),int(segment.y)+1):
			terrain.set_cell(Vector2i(x,int(segment.z)),0,Vector2i(2,0))
	terrain.update_internals()
	for x in [-9.0, width_tiles * TILE + 9.0]:
		var wall := StaticBody2D.new()
		wall.position = Vector2(x,0)
		wall.collision_layer = 1
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(18,600)
		shape.shape = rect
		wall.add_child(shape)
		add_child(wall)

func _draw() -> void:
	# Ground decorations are original code-drawn pixel art.
	for x in range(0,width_tiles):
		if x in pit_columns or x in obstacle_columns:
			continue
		var px := x * TILE
		if x % 7 == 2:
			draw_rect(Rect2(px+6,174,1,6),Color("5e914b"))
			draw_rect(Rect2(px+4,173,5,2),Color("fff0af"))
			draw_rect(Rect2(px+5,172,3,4),Color("ef9d72"))
		elif x % 9 == 0:
			draw_colored_polygon(PackedVector2Array([Vector2(px,180),Vector2(px+4,174),Vector2(px+5,179),Vector2(px+9,173),Vector2(px+11,180)]),Color("5a944a"))
	_sign(Vector2(126,179), "起点", true)
	_sign(Vector2(540,179), "跳!", true)
	_sign(Vector2(1332,179), "长按", true)
	_sign(Vector2(2025,179), "终点", true)
	for particle in particles:
		var color: Color = particle["color"]
		color.a = minf(particle["life"] * 3.0, 1.0)
		if particle["text"] == "":
			draw_rect(Rect2(particle["position"],Vector2(2,2)),color)
		else:
			draw_string(FONT,particle["position"],particle["text"],HORIZONTAL_ALIGNMENT_LEFT,-1,8,color)

func _sign(at: Vector2, text: String, arrow: bool) -> void:
	draw_rect(Rect2(at+Vector2(-1,-23),Vector2(2,23)),Color("8d654b"))
	draw_rect(Rect2(at+Vector2(-11,-28),Vector2(24,12)),Color("c4915f"))
	draw_rect(Rect2(at+Vector2(-10,-27),Vector2(22,10)),Color("eed19d"))
	draw_string(FONT,at+Vector2(-8,-19),text,HORIZONTAL_ALIGNMENT_LEFT,-1,7,Color("624b3c"))
	if arrow:
		draw_colored_polygon(PackedVector2Array([at+Vector2(14,-27),at+Vector2(20,-22),at+Vector2(14,-17)]),Color("c4915f"))
