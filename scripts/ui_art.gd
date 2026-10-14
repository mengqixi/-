extends Node2D
var panel_width := 242.0

func _draw() -> void:
	for x in [15.0,panel_width-23.0]:
		var at := Vector2(x,14)
		draw_rect(Rect2(at,Vector2(8,3)),Color("f4c85c"))
		draw_rect(Rect2(at+Vector2(2,-2),Vector2(4,7)),Color("f4c85c"))
		draw_rect(Rect2(at+Vector2(3,-4),Vector2(2,11)),Color("ffedaa"))
	for x in range(14,int(panel_width)-14,12):
		draw_rect(Rect2(x,155,6,1),Color("4b6996"))
