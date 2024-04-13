package game

import "core:math/linalg"
import rl "libs:raylib"

direction_to :: proc(vec, vec_to: rl.Vector2) -> rl.Vector2 {
	return linalg.normalize(vec_to - vec)
}
