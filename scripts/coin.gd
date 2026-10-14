extends Node2D

signal collected
var taken := false
var time := 0.0

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func try_collect(player_rect: Rect2) -> bool:
	if taken or not Rect2(position - Vector2(5, 6), Vector2(10, 12)).intersects(player_rect):
		return false
	taken = true
	visible = false
	set_process(false)
	collected.emit()
	return true

func _draw() -> void:
	var half_width := maxf(1.0, absf(cos(time * 3.0)) * 4.0)
	var lift := sin(time * 3.0 + position.x) * 1.0
	draw_rect(Rect2(-half_width, -5 + lift, half_width * 2, 10), Color("a97424"))
	draw_rect(Rect2(-half_width, -4 + lift, half_width * 2, 8), Color("f5c85c"))
	draw_rect(Rect2(-half_width + 1, -3 + lift, maxf(1, half_width - 1), 6), Color("ffeaa0"))
