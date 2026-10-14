extends CharacterBody2D

const FACE := preload("res://assets/icon.png")

var left_edge := 0.0
var right_edge := 0.0
var direction := -1.0
var defeated := false
var previous_position := Vector2.ZERO
var animation_time := 0.0

func _ready() -> void:
	process_physics_priority = 10

func _physics_process(delta: float) -> void:
	previous_position = position
	if defeated:
		return
	if position.x <= left_edge:
		direction = 1.0
	elif position.x >= right_edge:
		direction = -1.0
	velocity.x = direction * 25.0
	velocity.y = minf(velocity.y + 900.0 * delta, 500.0)
	move_and_slide()
	if is_on_wall():
		direction *= -1.0
	animation_time += delta * 7.0
	queue_redraw()

func body_rect() -> Rect2:
	return Rect2(position + Vector2(-7, -24), Vector2(14, 24))

func defeat() -> void:
	defeated = true
	visible = false
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)

func _draw() -> void:
	var step := 1.0 if sin(animation_time) > 0.0 else -1.0
	# The supplied picture is the head only. Torso, arms and feet are separate.
	draw_rect(Rect2(-9, -27, 18, 18), Color("694c74"))
	draw_rect(Rect2(-8, -26, 16, 16), Color("dfb8ce"))
	draw_texture_rect(FACE, Rect2(-7, -25, 14, 14), false)
	draw_rect(Rect2(-7, -9, 14, 6), Color("a76d9e"))
	draw_rect(Rect2(-9, -8, 3, 4), Color("835780"))
	draw_rect(Rect2(6, -8, 3, 4), Color("835780"))
	draw_rect(Rect2(-3, -8, 6, 4), Color("e7b679"))
	draw_rect(Rect2(-8 + step, -3, 6, 3), Color("243947"))
	draw_rect(Rect2(2 - step, -3, 6, 3), Color("243947"))
