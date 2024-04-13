package game

import "core:math"
import "core:math/linalg"
import rl "libs:raylib"

direction_to :: proc(vec, vec_to: rl.Vector2) -> rl.Vector2 {
	if linalg.length(vec_to - vec) <= 0.0001 {
		return rl.Vector2{0, 0}
	}

	return linalg.normalize(vec_to - vec)
}

aim_ahead :: proc(
	target_pos, gun_pos, target_velocity, gun_velocity: rl.Vector2,
	bullet_speed: f32,
) -> f32 {
	delta := target_pos - gun_pos
	vr := target_velocity - gun_velocity

	a := linalg.dot(vr, vr) - bullet_speed * bullet_speed
	b := 2.0 * linalg.dot(vr, delta)
	c := linalg.dot(delta, delta)

	desc := b * b - 4.0 * a * c

	if desc > 0.0 {
		return 2.0 * c / (math.sqrt(desc) - b)
	}

	return -1.0
}
