extends SceneTree

func _initialize() -> void:
	var image := Image.load_from_file("res://assets/user-icon.jpg")
	if image == null:
		push_error("图标照片无法读取")
		quit(1)
		return
	var sizes := [256,128,64,48,32,16]
	var buffers: Array[PackedByteArray] = []
	for dimension in sizes:
		var scaled := image.duplicate()
		scaled.resize(dimension,dimension,Image.INTERPOLATE_LANCZOS)
		scaled.convert(Image.FORMAT_RGBA8)
		buffers.append(scaled.save_png_to_buffer())
		if dimension == 256:
			scaled.save_png("res://assets/icon.png")
	var file := FileAccess.open("res://assets/icon.ico",FileAccess.WRITE)
	file.store_16(0)
	file.store_16(1)
	file.store_16(sizes.size())
	var offset := 6 + 16 * sizes.size()
	for i in range(sizes.size()):
		var dimension: int = sizes[i]
		file.store_8(0 if dimension == 256 else dimension)
		file.store_8(0 if dimension == 256 else dimension)
		file.store_8(0)
		file.store_8(0)
		file.store_16(1)
		file.store_16(32)
		file.store_32(buffers[i].size())
		file.store_32(offset)
		offset += buffers[i].size()
	for buffer in buffers:
		file.store_buffer(buffer)
	file.close()
	print("图标已生成：6 种尺寸，原照片内容保留")
	quit()
