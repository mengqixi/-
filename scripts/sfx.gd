extends Node

var sounds: Dictionary = {}
var muted := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	sounds["jump"] = _make_sound([370.0, 530.0, 690.0], 0.045)
	sounds["coin"] = _make_sound([880.0, 1320.0], 0.055)
	sounds["stomp"] = _make_sound([170.0, 100.0], 0.04)
	sounds["grow"] = _make_sound([220.0,330.0,440.0,660.0],0.045)
	sounds["hurt"] = _make_sound([450.0,290.0,150.0],0.06)
	sounds["death"] = _make_sound([440.0, 340.0, 250.0, 130.0], 0.10)
	sounds["clear"] = _make_sound([523.25, 659.25, 783.99, 1046.5], 0.15)

func play_sound(sound_name: String) -> void:
	if muted or not sounds.has(sound_name):
		return
	var player := AudioStreamPlayer.new()
	player.stream = sounds[sound_name]
	player.volume_db = -17.0
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func _make_sound(notes: Array, seconds: float) -> AudioStreamWAV:
	var data := PackedByteArray()
	var rate := 22050
	var count := int(seconds * rate)
	data.resize(count * notes.size() * 2)
	var cursor := 0
	for frequency in notes:
		for i in range(count):
			var t := float(i) / rate
			var envelope := minf(t * 100.0, 1.0) * maxf(0.0, 1.0 - float(i) / count)
			var sample := int(sin(TAU * float(frequency) * t) * envelope * 20000.0)
			data.encode_s16(cursor, sample)
			cursor += 2
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	return stream

func _exit_tree() -> void:
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	sounds.clear()
