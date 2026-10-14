extends StaticBody2D

signal reward_released(reward_type: String)
@export_enum("coin","mushroom") var reward_type := "coin"
var used := false
var bump_time := 0.0

func _ready() -> void:
	add_to_group("lucky_blocks")

func bump() -> void:
	if used:
		return
	used = true
	bump_time = 0.18
	reward_released.emit(reward_type)
	queue_redraw()

func _process(delta: float) -> void:
	if bump_time > 0:
		bump_time = maxf(0,bump_time-delta)
		queue_redraw()

func _draw() -> void:
	var lift := sin(bump_time / 0.18 * PI) * -4.0
	var at := Vector2(-9,-9+lift)
	draw_rect(Rect2(at,Vector2(18,18)),Color("482a20"))
	draw_rect(Rect2(at+Vector2(1,1),Vector2(16,16)),Color("a77645") if used else Color("f5b83f"))
	draw_rect(Rect2(at+Vector2(2,2),Vector2(14,1)),Color("c59460") if used else Color("ffe595"))
	for point in [Vector2(2,2),Vector2(14,2),Vector2(2,14),Vector2(14,14)]:
		draw_rect(Rect2(at+point,Vector2(2,2)),Color("774b29"))
	if not used:
		draw_rect(Rect2(at+Vector2(5,4),Vector2(8,2)),Color("fff5c6"))
		draw_rect(Rect2(at+Vector2(11,6),Vector2(2,3)),Color("fff5c6"))
		draw_rect(Rect2(at+Vector2(8,8),Vector2(4,2)),Color("fff5c6"))
		draw_rect(Rect2(at+Vector2(8,12),Vector2(2,2)),Color("fff5c6"))
