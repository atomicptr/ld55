package game

import "core:math/linalg"
import rl "libs:raylib"

BoidsConfig :: struct {
	rule2_threshold: Maybe(f32),
	rule2_extra_pos: Maybe(rl.Vector2),
}

boids :: proc(using self: ^Collection($Id, $T, $N), me: Id, config: BoidsConfig) -> rl.Vector2 {
	return(
		boids_rule1(self, me) +
		boids_rule2(self, me, config.rule2_threshold, config.rule2_extra_pos) +
		boids_rule3(self, me) \
	)
}

boids_rule1 :: proc(using self: ^Collection($Id, $T, $N), me: Id) -> rl.Vector2 {
	sum := rl.Vector2(0)

	for i in 0 ..< col_index {
		if me == Id(i) || !col_items[i].alive {
			continue
		}

		sum += col_items[i].position
	}

	center_of_mass := sum / f32(col_count)

	return direction_to(col_items[me].position, center_of_mass) / 100
}

boids_rule2 :: proc(
	using self: ^Collection($Id, $T, $N),
	me: Id,
	dist_threshold: Maybe(f32) = nil,
	extra_point: Maybe(rl.Vector2) = nil,
) -> rl.Vector2 {
	threshold, ok := dist_threshold.(f32)
	if !ok {
		threshold = 16.0
	}

	c := rl.Vector2(0)

	for i in 0 ..< col_index {
		if me == Id(i) || !col_items[i].alive {
			continue
		}

		if linalg.length(col_items[i].position - col_items[me].position) < threshold {
			c -= col_items[i].position - col_items[me].position
		}
	}

	extra_pos, ok_extra_pos := extra_point.(rl.Vector2)
	if ok_extra_pos {
		if linalg.length(extra_pos - col_items[me].position) < threshold {
			c -= extra_pos - col_items[me].position
		}
	}

	return c
}

boids_rule3 :: proc(using self: ^Collection($Id, $T, $N), me: Id) -> rl.Vector2 {
	vel := rl.Vector2(0)

	for i in 0 ..< col_index {
		if me == Id(i) || !col_items[i].alive {
			continue
		}

		vel += col_items[i].velocity
	}

	vel /= f32(col_count)

	return (vel - col_items[me].velocity) / 8
}
