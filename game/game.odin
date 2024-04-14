package game

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import "core:mem"
import rl "libs:raylib"

title :: "LD55"
window_width :: 1280
window_height :: 720
zoom :: 2.0

enemy_spawn_time :: 0.2
rando_drop_spawn_time :: 20.0

Game :: struct {
	player:            ^Player,
	em:                ^EnemyManager,
	mm:                ^MinionManager,
	pm:                ^ProjectileManager,
	dm:                ^DropsManager,
	enemy_spawn_timer: Timer,
	rando_drop_timer:  Timer,
	camera:            rl.Camera2D,
	total_timer:       f64,
	paused:            bool,
	game_over:         bool,
}

main :: proc() {
	when ODIN_DEBUG {
		fmt.println("### DEBUG MODE ENABLED ###")

		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	rl.InitWindow(window_width, window_height, title)
	defer rl.CloseWindow()

	rl.SetTargetFPS(60)
	rl.SetExitKey(rl.KeyboardKey.KEY_NULL)

	b = broker_create()

	game := create()
	broker_register(b, .PlayerGotHit, &game, game_on_message)
	broker_register(b, .PlayerDied, &game, game_on_message)
	broker_register(b, .EnemyGotHit, &game, game_on_message)
	broker_register(b, .EnemyDied, &game, game_on_message)
	broker_register(b, .DropPickup, &game, game_on_message)

	for !rl.WindowShouldClose() {
		update(&game)
		draw(&game)
	}

	destroy(&game)
}

game_on_message :: proc(receiver: rawptr, msg_type: MessageType, msg_data: MessageData) {
	game := cast(^Game)receiver

	#partial switch msg_type {
	case .PlayerDied:
		game.game_over = true
	case .PlayerGotHit:
		#partial switch data in msg_data {
		case EmptyMsg:
		// got damage from projectile or something else
		case EnemyMsg:
			enemy_manager_kill(game.em, data.enemy)
		}

		// TODO: maybe do something with the enemy type?
		player_process_hit(game.player)
	case .EnemyGotHit:
		data := msg_data.(EnemyMsg)
		enemy_manager_kill(game.em, data.enemy)
	case .EnemyDied:
		data := msg_data.(AtLocationMsg)
		drops_manager_rng_drop(game.dm, {.Health, .MinionShooter}, data.position)
	case .DropPickup:
		data := msg_data.(DropPickupMsg)
		switch data.type {
		case .Health:
			if game.player.health == game.player.max_health {
				return
			}
			game.player.health += 1
		case .MinionShooter:
			minion_manager_spawn(game.mm, .Shooter, game.player.position)
		}
	}
}

create :: proc() -> Game {
	game := Game{}
	game.player = player_create()
	game.camera = rl.Camera2D {
		{window_width / 2 - player_size / 2, window_height / 2 - player_size / 2},
		0,
		0,
		zoom,
	}
	game.em = enemy_manager_create(game.player)
	game.pm = projectile_manager_create(game.player, game.em)
	game.mm = minion_manager_create(game.player, game.em, game.pm)
	game.dm = drops_manager_create(game.player)
	game.enemy_spawn_timer = timer_create(enemy_spawn_time)
	game.rando_drop_timer = timer_create(rando_drop_spawn_time)

	reset(&game)

	return game
}

reset :: proc(using game: ^Game) {
	enemy_manager_reset(game.em)
	projectile_manager_reset(game.pm)
	minion_manager_reset(game.mm)
	drops_manager_reset(game.dm)

	player.position = {0, 0}
	player.health = player_initial_hp
	player.max_health = player_initial_hp

	timer_reset(&enemy_spawn_timer)
	timer_reset(&rando_drop_timer)
	// force the game to do this directly once at launch
	rando_drop_timer.finished = true

	total_timer = 0.0
	game_over = false
}

update :: proc(using game: ^Game) {
	dt := rl.GetFrameTime()

	broker_process_messages(b)

	if game_over {
		if rl.IsKeyPressed(rl.KeyboardKey.ENTER) {
			reset(game)
		}
		return
	}

	if rl.IsKeyPressed(rl.KeyboardKey.ESCAPE) {
		paused = !paused
	}

	if paused {
		return
	}

	timer_update(&enemy_spawn_timer, dt)
	timer_update(&rando_drop_timer, dt)

	if enemy_spawn_timer.finished {
		enemy_spawn(
			em,
			EnemyType.Grunt,
			create_random_position_outside_of_bounds(
				{player.position.x, player.position.y, window_width / zoom, window_height / zoom},
			),
		)
		timer_reset(&enemy_spawn_timer)
	}

	// will trigger instantly
	if rando_drop_timer.finished {
		drops_manager_spawn(
			dm,
			.MinionShooter,
			create_random_position_outside_of_bounds(
				{player.position.x, player.position.y, window_width / zoom, window_height / zoom},
			),
		)
		timer_reset(&rando_drop_timer)
	}

	camera.target = player.position

	enemy_manager_update(em, dt)
	minion_manager_update(mm, dt)
	projectile_manager_update(pm, dt)
	drops_manager_update(dm, dt)
	player_update(player, dt)

	total_timer += f64(dt)
}

create_random_position_outside_of_bounds :: proc(bounds: rl.Rectangle) -> rl.Vector2 {
	direction := linalg.normalize(
		rl.Vector2{rand.float32_range(-1.0, 1.0), rand.float32_range(-1.0, 1.0)},
	)

	return {bounds.x, bounds.y} + direction * {100 + bounds.width * 0.5, 100 + bounds.height * 0.5}
}

draw :: proc(using game: ^Game) {
	rl.BeginDrawing()
	defer rl.EndDrawing()

	rl.ClearBackground(rl.RAYWHITE)

	{
		rl.BeginMode2D(camera)
		defer rl.EndMode2D()

		rl.DrawRectangleRec({100, 100, 100, 100}, rl.GRAY)

		enemy_manager_draw(em)
		minion_manager_draw(mm)
		projectile_manager_draw(pm)
		drops_manager_draw(dm)
		player_draw(player)
	}

	if paused {
		rl.DrawRectangleRec({0.0, 0.0, window_width, window_height}, rl.Color{0, 0, 0, 125})
		rl.DrawText("PAUSED", window_width / 2 - 100, window_height / 2 - 25, 50, rl.WHITE)
	}

	if game_over {
		rl.DrawRectangleRec({0.0, 0.0, window_width, window_height}, rl.Color{0, 0, 0, 125})
		rl.DrawText("GAME OVER", window_width / 2 - 150, window_height / 2 - 25, 50, rl.WHITE)
		rl.DrawText(
			"Press ENTER to restart",
			window_width / 2 - 130,
			window_height / 2 + 50,
			20,
			rl.WHITE,
		)
	}

	rl.DrawText(fmt.ctprintf("%3.1fs", total_timer), window_width - 100, 10, 20, rl.BLACK)

	when ODIN_DEBUG {
		rl.DrawFPS(10, 10)
		rl.DrawText(fmt.ctprintf("Health: %d", player.health), 10, 30, 20, rl.BLACK)
		rl.DrawText(
			fmt.ctprintf("Enemies: %d (Idx: %d)", em.col_count, em.col_index),
			10,
			50,
			20,
			rl.BLACK,
		)
		rl.DrawText(
			fmt.ctprintf("Minions: %d (Idx: %d)", mm.col_count, mm.col_index),
			10,
			70,
			20,
			rl.BLACK,
		)
		rl.DrawText(
			fmt.ctprintf("Projectile: %d (Idx: %d)", pm.col_count, pm.col_index),
			10,
			90,
			20,
			rl.BLACK,
		)
		rl.DrawText(
			fmt.ctprintf("Drops: %d (Idx: %d)", dm.col_count, dm.col_index),
			10,
			110,
			20,
			rl.BLACK,
		)
	}
}

destroy :: proc(game: ^Game) {
	drops_manager_destroy(game.dm)
	projectile_manager_destroy(game.pm)
	minion_manager_destroy(game.mm)
	enemy_manager_destroy(game.em)
	player_destroy(game.player)
	broker_destroy(b)
}
