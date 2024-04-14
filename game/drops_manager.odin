package game

import "core:fmt"
import rl "libs:raylib"

drops_max :: 2048
drop_size :: 2

DropId :: distinct uint

DropsType :: enum {
	Health,
}

drop_chance := [DropsType]f32 {
	.Health = 0.1,
}

Drop :: struct {
	id:         DropId,
	alive:      bool,
	type:       DropsType,
	position:   rl.Vector2,
	has_arrows: bool,
}

DropsManager :: struct {
	using collection: Collection(DropId, Drop, drops_max),
	player:           ^Player,
}

drops_manager_create :: proc(player: ^Player) -> ^DropsManager {
	dm := new(DropsManager)
	dm.player = player
	return dm
}

drops_manager_spawn :: proc(using self: ^DropsManager, type: DropsType, position: rl.Vector2) {
	new_index, ok := col_new_id(&self.collection)
	if !ok {
		return
	}

	col_items[new_index].id = new_index
	col_items[new_index].alive = true
	col_items[new_index].type = type
	col_items[new_index].position = position
	col_items[new_index].has_arrows = true // TODO: change this depending on type
}

drops_manager_rng_drop :: proc(using self: ^DropsManager, type: DropsType, position: rl.Vector2) {
	if !chance_was_successful(drop_chance[type]) {
		return
	}
	drops_manager_spawn(self, type, position)
}

drops_manager_update :: proc(using self: ^DropsManager, dt: f32) {
	for i in 0 ..< col_index {
		if !col_items[i].alive {
			continue
		}

		if rl.CheckCollisionRecs(
			   {col_items[i].position.x, col_items[i].position.y, drop_size, drop_size},
			   {player.position.x, player.position.y, player_size, player_size},
		   ) {
			broker_post(b, .DropPickup, DropPickupMsg{col_items[i].type})
			drops_manager_kill(self, DropId(i))
		}
	}
}

drops_manager_draw :: proc(using self: ^DropsManager) {
	for i in 0 ..< col_index {
		if !col_items[i].alive {
			continue
		}

		rl.DrawCircle(
			i32(col_items[i].position.x),
			i32(col_items[i].position.y),
			drop_size,
			rl.DARKPURPLE,
		)
	}
}

drops_manager_kill :: proc(using self: ^DropsManager, drop: DropId) {
	col_free_id(&self.collection, drop)
}

drops_manager_destroy :: proc(using self: ^DropsManager) {
	free(self)
}
