package game

Timer :: struct {
	threshold: f32,
	value:     f32,
	finished:  bool,
}

timer_create :: proc(threshold: f32, autostart: bool = true) -> Timer {
	return {threshold, 0.0, !autostart}
}

timer_update :: proc(using self: ^Timer, dt: f32) {
	if finished {
		return
	}

	value += dt
	if value >= threshold {
		finished = true
	}
}

timer_reset :: proc(using self: ^Timer) {
	value = 0.0
	finished = false
}
