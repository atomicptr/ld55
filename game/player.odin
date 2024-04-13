package game

import "core:math/linalg"
import rl "libs:raylib"

player_max_speed :: 2.0
player_acceleration :: 12.5
player_friction :: player_acceleration

Player :: struct {
	position: rl.Vector2,
	velocity: rl.Vector2,
}

player_create :: proc() -> ^Player {
	player := new(Player)
	player.position = {0.0, 0.0}

	return player
}

player_update :: proc(using self: ^Player, dt: f32) {
	direction := rl.Vector2(0)

	if rl.IsKeyDown(rl.KeyboardKey.W) || rl.IsKeyDown(rl.KeyboardKey.UP) {
		direction.y = -1.0
	}

	if rl.IsKeyDown(rl.KeyboardKey.S) || rl.IsKeyDown(rl.KeyboardKey.DOWN) {
		direction.y = 1.0
	}

	if rl.IsKeyDown(rl.KeyboardKey.A) || rl.IsKeyDown(rl.KeyboardKey.LEFT) {
		direction.x = -1.0
	}

	if rl.IsKeyDown(rl.KeyboardKey.D) || rl.IsKeyDown(rl.KeyboardKey.RIGHT) {
		direction.x = 1.0
	}

	direction = linalg.normalize(direction)

	if linalg.length(direction) > 0.0 {
		velocity = rl.Vector2MoveTowards(
			velocity,
			direction * player_max_speed,
			player_acceleration * dt,
		)
	} else {
		velocity = rl.Vector2MoveTowards(velocity, rl.Vector2(0), player_friction * dt)
	}

	position += velocity
}

player_draw :: proc(using self: ^Player) {
	rl.DrawRectangleRec({position.x, position.y, 8, 8}, rl.GREEN)
}

player_destroy :: proc(self: ^Player) {
	free(self)
}
