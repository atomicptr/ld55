package game

import "core:fmt"
import "core:mem"
import rl "libs:raylib"

title :: "LD55"
window_width :: 1280
window_height :: 720

Game :: struct {
	player: ^Player,
	camera: rl.Camera2D,
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
	game.camera = rl.Camera2D{{window_width / 2 - 4, window_height / 2 - 4}, 0, 0, 2.0}
	return game
}

update :: proc(using game: ^Game) {
	dt := rl.GetFrameTime()

	camera.target = player.position

	player_update(player, dt)
}

draw :: proc(using game: ^Game) {
	rl.BeginDrawing()
	defer rl.EndDrawing()

	rl.ClearBackground(rl.RAYWHITE)

	{
		rl.BeginMode2D(camera)
		defer rl.EndMode2D()

		rl.DrawRectangleRec({100, 100, 100, 100}, rl.GRAY)

		player_draw(player)
	}

	rl.DrawFPS(10, 10)
}

destroy :: proc(game: ^Game) {
	player_destroy(game.player)
}
