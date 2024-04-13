package main

import "../game"
import "core:math/rand"
import "core:mem"
import "core:runtime"
import rl "libs:raylib"

foreign import "odin_env"

ctx: runtime.Context

tempAllocatorData: [mem.Megabyte * 4]byte
tempAllocatorArena: mem.Arena

mainMemoryData: [mem.Megabyte * 16]byte
mainMemoryArena: mem.Arena

game_obj: game.Game

@(export, link_name = "game_init")
game_init :: proc "c" () {
	ctx = runtime.default_context()
	context = ctx

	mem.arena_init(&mainMemoryArena, mainMemoryData[:])
	mem.arena_init(&tempAllocatorArena, tempAllocatorData[:])

	ctx.allocator = mem.arena_allocator(&mainMemoryArena)
	ctx.temp_allocator = mem.arena_allocator(&tempAllocatorArena)

	rl.InitWindow(game.window_width, game.window_height, game.title)
	rl.SetTargetFPS(60)

	game_obj = game.create()
}

@(export, link_name = "game_update")
game_update :: proc "contextless" () {
	context = ctx

	free_all(context.temp_allocator)
	game.update(&game_obj)
	game.draw(&game_obj)
}
