extends CharacterBody2D

var direction := 1.0
var collected := false

func _ready() -> void:
	process_physics_priority = 10

func _physics_process(delta: float) -> void:
	if collected:
		return
	velocity.x = 32.0*direction
	velocity.y = minf(velocity.y+900.0*delta,500.0)
	move_and_slide()
	if is_on_wall():
		direction *= -1
	if position.y > 270:
		queue_free()

func try_collect(player_rect: Rect2) -> bool:
	if collected or not Rect2(position+Vector2(-6,-14),Vector2(12,14)).intersects(player_rect):
		return false
	collected = true
	queue_free()
	return true

func _draw() -> void:
	draw_rect(Rect2(-4,-7,8,7),Color("fff0bd"))
	draw_rect(Rect2(-4,-2,8,2),Color("dba56d"))
	draw_rect(Rect2(-7,-10,14,4),Color("9e322b"))
	draw_rect(Rect2(-6,-13,12,6),Color("e34835"))
	draw_rect(Rect2(-3,-15,6,3),Color("e34835"))
	draw_rect(Rect2(-4,-12,3,3),Color("fff5d0"))
	draw_rect(Rect2(2,-10,3,3),Color("fff5d0"))
	draw_rect(Rect2(-1,-15,2,3),Color("fff5d0"))
