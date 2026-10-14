extends Node2D

func _draw() -> void:
	# A green pipe wraps the existing two-tile obstacle and its collision.
	var pipe_x := 51.0 * 18.0
	draw_rect(Rect2(pipe_x,144,36,36),Color("286b40"))
	draw_rect(Rect2(pipe_x+2,146,32,34),Color("4fa649"))
	draw_rect(Rect2(pipe_x+5,145,5,35),Color("9fce63"))
	draw_rect(Rect2(pipe_x+28,145,4,35),Color("378943"))
	draw_rect(Rect2(pipe_x,144,36,8),Color("245e38"))
	draw_rect(Rect2(pipe_x+1,145,34,5),Color("7ac454"))
	draw_rect(Rect2(pipe_x+3,145,28,1),Color("b7df7b"))
	var at := Vector2(2117,180)
	draw_rect(Rect2(at+Vector2(0,-31),Vector2(36,31)),Color("ad8467"))
	draw_rect(Rect2(at+Vector2(2,-30),Vector2(32,30)),Color("dbbda0"))
	for x in [0,12,24]:
		draw_rect(Rect2(at+Vector2(x,-37),Vector2(12,7)),Color("ad8467"))
		draw_rect(Rect2(at+Vector2(x+2,-37),Vector2(7,5)),Color("e6cbb0"))
	for y in [-24,-15,-6]:
		draw_rect(Rect2(at+Vector2(0,y),Vector2(36,1)),Color("bf9c7d"))
	draw_rect(Rect2(at+Vector2(12,-20),Vector2(12,20)),Color("765c50"))
	draw_rect(Rect2(at+Vector2(14,-21),Vector2(8,21)),Color("4b4f46"))
	draw_rect(Rect2(at+Vector2(5,-24),Vector2(4,7)),Color("657568"))
	draw_rect(Rect2(at+Vector2(27,-24),Vector2(4,7)),Color("657568"))
