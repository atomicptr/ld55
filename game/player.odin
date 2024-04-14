package game

import "core:fmt"
import "core:math/linalg"
import "libs:anima"
import "libs:anima/anima_fsm"
import arl "libs:anima_raylib_custom"
import rl "libs:raylib"

player_max_speed :: 2.0
player_acceleration :: 12.5
player_friction :: player_acceleration
player_size :: 8
player_initial_hp :: 5
player_iframe_threshold :: 1.0

PlayerAnim :: enum u8 {
	IdleRight,
	IdleLeft,
	WalkRight,
	WalkLeft,
}

Player :: struct {
	position:      rl.Vector2,
	velocity:      rl.Vector2,
	health:        uint,
	max_health:    uint,
	iframe_timer:  Timer,
	iframe_active: bool,
	anim:          ^anima_fsm.FSM(PlayerAnim),
	texture:       rl.Texture,
}

player_create :: proc() -> ^Player {
	player := new(Player)
	player.position = {0.0, 0.0}
	player.health = player_initial_hp
	player.max_health = player_initial_hp
	player.iframe_timer = timer_create(player_iframe_threshold, false)

	image := rl.LoadImage("assets/sprites/player.png")
	defer rl.UnloadImage(image)

	player.texture = rl.LoadTextureFromImage(image)

	g := anima.new_grid(8, 8, uint(player.texture.width), uint(player.texture.height))

	player.anim = anima_fsm.create(PlayerAnim)

	anima_fsm.add(
		player.anim,
		PlayerAnim.IdleRight,
		anima.new_animation(anima.grid_frames(&g, 0, 0), 1.0, flip_v = false),
	)
	anima_fsm.add(
		player.anim,
		PlayerAnim.IdleLeft,
		anima.new_animation(anima.grid_frames(&g, 0, 0), 1.0, flip_v = true),
	)
	anima_fsm.add(
		player.anim,
		PlayerAnim.WalkRight,
		anima.new_animation(anima.grid_frames(&g, "0-2", 0), 0.16, flip_v = false),
	)
	anima_fsm.add(
		player.anim,
		PlayerAnim.WalkLeft,
		anima.new_animation(anima.grid_frames(&g, "0-2", 0), 0.16, flip_v = true),
	)

	anima_fsm.play(player.anim, PlayerAnim.IdleRight)

	return player
}

player_update :: proc(using self: ^Player, dt: f32) {
	timer_update(&iframe_timer, dt)
	anima_fsm.update(anim, dt)

	if linalg.length(velocity) > 0.0 {
		anima_fsm.play(anim, velocity.x >= 0 ? PlayerAnim.WalkRight : PlayerAnim.WalkLeft)
	} else {
		anima_fsm.play(anim, velocity.x >= 0 ? PlayerAnim.IdleRight : PlayerAnim.IdleLeft)
	}

	if iframe_active && iframe_timer.finished {
		iframe_active = false
		iframe_timer.threshold = player_iframe_threshold
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
	arl.fsm_draw(anim, texture, position.x, position.y)
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

	health -= 1
	iframe_active = true
	timer_reset(&iframe_timer)
}

player_destroy :: proc(using self: ^Player) {
	anima_fsm.destroy(anim)
	free(self)
}
