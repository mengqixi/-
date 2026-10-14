extends CharacterBody2D

signal jumped

const SPEED := 110.0
const GRAVITY := 900.0
const JUMP_SPEED := -300.0
var previous_position := Vector2.ZERO
var previous_velocity := Vector2.ZERO
var enabled := false
var facing := 1.0
var animation_time := 0.0
var jump_cut := false
var is_big := false
var pending_growth := false
var invincible_time := 0.0
var jumps_used := 0

func _physics_process(delta: float) -> void:
	previous_position = position
	if not enabled:
		previous_velocity = Vector2.ZERO
		return
	invincible_time = maxf(0.0,invincible_time-delta)
	if pending_growth:
		_try_growth()
	var direction := Input.get_axis("move_left", "move_right")
	velocity.x = move_toward(velocity.x, direction * SPEED, (900.0 if direction else 1200.0) * delta)
	if direction != 0.0:
		facing = signf(direction)
	velocity.y = minf(velocity.y + GRAVITY * delta, 500.0)
	if is_on_floor():
		jumps_used = 0
	if Input.is_action_just_pressed("jump") and jumps_used < 2:
		velocity.y = JUMP_SPEED if jumps_used == 0 else -270.0
		jumps_used += 1
		jump_cut = false
		jumped.emit()
	if Input.is_action_just_released("jump") and velocity.y < 0.0 and not jump_cut:
		velocity.y *= 0.5
		jump_cut = true
	previous_velocity = velocity
	move_and_slide()
	animation_time += delta * (absf(velocity.x) / 12.0)
	queue_redraw()

func body_rect() -> Rect2:
	var height := 28.0 if is_big else 16.0
	return Rect2(position + Vector2(-6, -height), Vector2(12, height))

func grow() -> void:
	if is_big:
		return
	pending_growth = true
	_try_growth()

func _try_growth() -> void:
	var room := RectangleShape2D.new()
	room.size = Vector2(11.5,27.5)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = room
	query.transform = Transform2D(0,global_position+Vector2(0,-14))
	query.collision_mask = 1
	if not get_world_2d().direct_space_state.intersect_shape(query,1).is_empty():
		return
	pending_growth = false
	is_big = true
	_resize_collision(28)
	queue_redraw()

func take_hit() -> bool:
	if invincible_time > 0.0:
		return false
	if is_big:
		is_big = false
		pending_growth = false
		invincible_time = 1.5
		_resize_collision(16)
		queue_redraw()
		return false
	return true

func _resize_collision(height: float) -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(12,height)
	$CollisionShape2D.shape = shape
	$CollisionShape2D.position.y = -height/2

func bounce() -> void:
	velocity.y = -180.0
	jump_cut = true
	jumps_used = 1

func _draw() -> void:
	if invincible_time > 0.0 and int(invincible_time*14)%2 == 0:
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing*(1.1 if is_big else 1.0),1.5 if is_big else 1.0))
	# Original tiny adventurer: golden cap, coral shirt and blue overalls.
	var skin := Color("ffdda3")
	var cap := Color("e44836")
	var red := Color("e44836")
	var blue := Color("397cad")
	var dark := Color("253c47")
	var stride := 2.0 if enabled and is_on_floor() and absf(velocity.x) > 5.0 and sin(animation_time) > 0.0 else 0.0
	draw_rect(Rect2(-5, -20, 10, 3), dark)
	draw_rect(Rect2(-6, -19, 11, 3), cap)
	draw_rect(Rect2(-5, -16, 13, 2), cap)
	draw_rect(Rect2(-5, -14, 10, 6), skin)
	draw_rect(Rect2(-5, -14, 3, 4), Color("805637"))
	draw_rect(Rect2(2, -13, 2, 3), dark)
	draw_rect(Rect2(4, -11, 3, 2), skin)
	draw_rect(Rect2(-6, -8, 12, 5), red)
	draw_rect(Rect2(-7, -6, 3, 3), skin)
	draw_rect(Rect2(5, -6, 3, 3), skin)
	draw_rect(Rect2(-3, -8, 2, 5), blue)
	draw_rect(Rect2(2, -8, 2, 5), blue)
	draw_rect(Rect2(-4, -5, 9, 3), blue)
	draw_rect(Rect2(-5 - stride, -2, 5, 2), dark)
	draw_rect(Rect2(1 + stride, -2, 5, 2), dark)
	draw_rect(Rect2(-2, -5, 1, 1), Color("ffdc71"))
	draw_rect(Rect2(3, -5, 1, 1), Color("ffdc71"))
	draw_set_transform(Vector2.ZERO)
