extends Node2D

var scroll := 0.0
var time := 0.0
var menu_mode := false

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0,0,360,216),Color("5c94fc"))
	for i in range(5):
		var x := fposmod(i*92.0+6-scroll*0.08+time*1.2,430.0)-35.0
		_cloud(Vector2(x,27+(i%3)*19))
	for i in range(-1,3):
		var x := i*240.0-fmod(scroll*0.20,240.0)
		_hill(Vector2(x+44,180),45,58,Color("4bd13e"),Color("168a37"))
		_hill(Vector2(x+162,180),27,32,Color("4bd13e"),Color("168a37"))
		_bush(Vector2(x+104,180))
	if menu_mode:
		draw_rect(Rect2(0,180,360,36),Color("ba653c"))
		for i in range(24):
			for y in [180,198]:
				draw_rect(Rect2(i*18,y,18,1),Color("4b3028"))
				draw_rect(Rect2(i*18,y+1,1,17),Color("4b3028"))
				draw_rect(Rect2(i*18+2,y+2,14,1),Color("f1b584"))
				draw_rect(Rect2(i*18+9,y+4,1,12),Color("794529"))
		_pipe(Vector2(19,180),23,24)
		for x in [77,95,267]:
			_block(Vector2(x,137))
		return
	draw_rect(Rect2(0,180,360,36),Color("4b969e"))
	for i in range(24):
		var x := fposmod(i*19.0-scroll*0.55+time*8.0,380.0)-10.0
		draw_rect(Rect2(x,192+(i%3)*5,11,1),Color("8bd1d2"))

func _hill(at: Vector2, width: float, height: float, color: Color, shade: Color) -> void:
	var points := PackedVector2Array([at+Vector2(-width,0),at+Vector2(-width,-height*.22),at+Vector2(-width*.8,-height*.22),at+Vector2(-width*.8,-height*.5),at+Vector2(-width*.6,-height*.5),at+Vector2(-width*.6,-height*.72),at+Vector2(-width*.35,-height*.72),at+Vector2(-width*.35,-height*.92),at+Vector2(-width*.13,-height*.92),at+Vector2(-width*.13,-height),at+Vector2(width*.13,-height),at+Vector2(width*.13,-height*.92),at+Vector2(width*.35,-height*.92),at+Vector2(width*.35,-height*.72),at+Vector2(width*.6,-height*.72),at+Vector2(width*.6,-height*.5),at+Vector2(width*.8,-height*.5),at+Vector2(width*.8,-height*.22),at+Vector2(width,-height*.22),at+Vector2(width,0)])
	draw_colored_polygon(points,color)
	points.append(points[0])
	draw_polyline(points,Color("284b31"),1)
	draw_rect(Rect2(at+Vector2(-9,-height+18),Vector2(2,7)),shade)
	draw_rect(Rect2(at+Vector2(7,-height+18),Vector2(2,7)),shade)

func _bush(at: Vector2) -> void:
	draw_rect(Rect2(at+Vector2(-21,-9),Vector2(44,9)),Color("285839"))
	draw_rect(Rect2(at+Vector2(-15,-15),Vector2(30,15)),Color("285839"))
	draw_rect(Rect2(at+Vector2(-7,-19),Vector2(16,19)),Color("285839"))
	draw_rect(Rect2(at+Vector2(-20,-8),Vector2(42,8)),Color("48c943"))
	draw_rect(Rect2(at+Vector2(-14,-14),Vector2(28,14)),Color("48c943"))
	draw_rect(Rect2(at+Vector2(-6,-18),Vector2(14,18)),Color("48c943"))
	draw_rect(Rect2(at+Vector2(-11,-10),Vector2(2,3)),Color("b0dc87"))
	draw_rect(Rect2(at+Vector2(6,-14),Vector2(2,3)),Color("b0dc87"))

func _cloud(at: Vector2) -> void:
	var points := PackedVector2Array([at+Vector2(-12,12),at+Vector2(-12,7),at+Vector2(-8,7),at+Vector2(-8,1),at+Vector2(-1,1),at+Vector2(-1,-4),at+Vector2(6,-4),at+Vector2(6,-9),at+Vector2(17,-9),at+Vector2(17,-4),at+Vector2(24,-4),at+Vector2(24,1),at+Vector2(30,1),at+Vector2(30,7),at+Vector2(34,7),at+Vector2(34,12)])
	draw_colored_polygon(points,Color("ffffff"))
	points.append(points[0])
	draw_polyline(points,Color("354c93"),1)
	draw_rect(Rect2(at+Vector2(-8,9),Vector2(38,2)),Color("d5e7ff"))

func _pipe(at: Vector2, width: float, height: float) -> void:
	draw_rect(Rect2(at+Vector2(-width*.5,-height),Vector2(width,height)),Color("286c42"))
	draw_rect(Rect2(at+Vector2(-width*.5+2,-height),Vector2(width-5,height)),Color("4fa64f"))
	draw_rect(Rect2(at+Vector2(-width*.5+4,-height),Vector2(3,height)),Color("a2d665"))
	draw_rect(Rect2(at+Vector2(-width*.5-2,-height-3),Vector2(width+4,7)),Color("286c42"))
	draw_rect(Rect2(at+Vector2(-width*.5,-height-2),Vector2(width,5)),Color("7dc95a"))

func _block(at: Vector2) -> void:
	draw_rect(Rect2(at,Vector2(17,17)),Color("a4673c"))
	draw_rect(Rect2(at+Vector2(1,1),Vector2(15,14)),Color("e6ae58"))
	draw_rect(Rect2(at+Vector2(4,3),Vector2(9,2)),Color("fff0af"))
	draw_rect(Rect2(at+Vector2(10,5),Vector2(3,4)),Color("fff0af"))
	draw_rect(Rect2(at+Vector2(7,8),Vector2(5,2)),Color("fff0af"))
	draw_rect(Rect2(at+Vector2(7,12),Vector2(3,2)),Color("fff0af"))
