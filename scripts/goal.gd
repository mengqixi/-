extends Node2D

signal reached
var triggered := false
var time := 0.0

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func try_reach(player_rect: Rect2) -> bool:
	if triggered or not Rect2(position + Vector2(-5, -58), Vector2(25, 58)).intersects(player_rect):
		return false
	triggered = true
	reached.emit()
	return true

func _draw() -> void:
	draw_rect(Rect2(-1, -62, 3, 62), Color("e9f0d7"))
	draw_rect(Rect2(2, -62, 1, 62), Color("6b8d8c"))
	draw_rect(Rect2(-3, -65, 7, 4), Color("f9d171"))
	var wave := sin(time * 4.0) * 2.0
	draw_colored_polygon(PackedVector2Array([Vector2(2,-59),Vector2(27,-56+wave),Vector2(23,-43+wave),Vector2(2,-46)]), Color("e5684e"))
	draw_rect(Rect2(8, -54, 4, 4), Color("fff0bb"))
	draw_rect(Rect2(12, -50, 4, 4), Color("fff0bb"))
	draw_rect(Rect2(-5, -3, 12, 3), Color("e3b44b"))
