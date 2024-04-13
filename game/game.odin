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

enemy_spawn_time :: 1.0

Game :: struct {
	player:            ^Player,
	em:                ^EnemyManager,
	enemy_spawn_timer: Timer,
	camera:            rl.Camera2D,
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

	game := create()

	for !rl.WindowShouldClose() {
		update(&game)
		draw(&game)
	}

	destroy(&game)
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
	game.enemy_spawn_timer = timer_create(enemy_spawn_time)
	return game
}

update :: proc(using game: ^Game) {
	dt := rl.GetFrameTime()

	timer_update(&enemy_spawn_timer, dt)

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

	camera.target = player.position

	enemy_manager_update(em, dt)
	player_update(player, dt)
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
		player_draw(player)
	}

	rl.DrawFPS(10, 10)
	rl.DrawText(fmt.ctprintf("Enemies: %d", em.enemy_index), 10, 30, 20, rl.BLACK)
}

destroy :: proc(game: ^Game) {
	enemy_manager_destroy(game.em)
	player_destroy(game.player)
}
