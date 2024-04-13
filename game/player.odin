package game

import "core:fmt"
import "core:math/linalg"
import rl "libs:raylib"

player_max_speed :: 2.0
player_acceleration :: 12.5
player_friction :: player_acceleration
player_size :: 8
player_initial_hp :: 5
player_iframe_threshold :: 1.0

Player :: struct {
	position:      rl.Vector2,
	velocity:      rl.Vector2,
	health:        uint,
	iframe_timer:  Timer,
	iframe_active: bool,
}

player_create :: proc() -> ^Player {
	player := new(Player)
	player.position = {0.0, 0.0}
	player.health = player_initial_hp
	player.iframe_timer = timer_create(player_iframe_threshold, false)

	return player
}

player_update :: proc(using self: ^Player, dt: f32) {
	timer_update(&iframe_timer, dt)

	if iframe_active && iframe_timer.finished {
		iframe_active = false
	}

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
	rl.DrawRectangleRec({position.x, position.y, player_size, player_size}, rl.GREEN)
}

player_process_hit :: proc(using self: ^Player) {
	if iframe_active {
		return
	}

	if health <= 1 {
		health = 0
		broker_post(b, .PlayerDied, EmptyMsg{})
		return
	}

	fmt.println("you got hit!")

	health -= 1
	iframe_active = true
	timer_reset(&iframe_timer)
}

player_destroy :: proc(self: ^Player) {
	free(self)
}
