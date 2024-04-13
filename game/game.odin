package game

import rl "libs:/raylib"

title :: "Odin Raylib Web Starter"
window_width :: 800
window_height :: 800

Game :: struct {
	box_pos: rl.Vector2,
}

main :: proc() {
	rl.InitWindow(window_width, window_height, title)
	defer rl.CloseWindow()

	rl.SetTargetFPS(60)

	game := create()

	for !rl.WindowShouldClose() {
		update(&game)
		draw(&game)
	}
}

create :: proc() -> Game {
	game := Game{}
	game.box_pos = {100.0, 100.0}
	return game
}

update :: proc(using game: ^Game) {
	dt := rl.GetFrameTime()

	if rl.IsKeyDown(rl.KeyboardKey.W) {
		box_pos.y -= 100.0 * dt
	}

	if rl.IsKeyDown(rl.KeyboardKey.S) {
		box_pos.y += 100.0 * dt
	}

	if rl.IsKeyDown(rl.KeyboardKey.A) {
		box_pos.x -= 100.0 * dt
	}

	if rl.IsKeyDown(rl.KeyboardKey.D) {
		box_pos.x += 100.0 * dt
	}
}

draw :: proc(using game: ^Game) {
	rl.BeginDrawing()
	rl.ClearBackground(rl.RAYWHITE)

	rl.DrawRectangleRec({box_pos.x, box_pos.y, 100, 100}, rl.RED)

	rl.DrawFPS(10, 10)

	rl.EndDrawing()
}
