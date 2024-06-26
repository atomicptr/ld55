package game

import "core:fmt"
import "core:math"
import "core:math/linalg"
import rl "libs:raylib"

drops_max :: 4096
drop_size :: 2
drop_arrow_offset :: 20.0
drop_max_arrows :: 3
drop_despawn_time :: 15.0

DropId :: distinct uint

DropsType :: enum {
	Health,
	MinionShooter,
}

drop_chance := [DropsType]f32 {
	.Health        = 0.05,
	.MinionShooter = 0.02,
}

drop_has_arrows := [DropsType]bool {
	.Health        = false,
	.MinionShooter = true,
}

Drop :: struct {
	id:            DropId,
	alive:         bool,
	type:          DropsType,
	position:      rl.Vector2,
	has_arrows:    bool,
	despawn_timer: Timer,
}

DropsManager :: struct {
	using collection: Collection(DropId, Drop, drops_max),
	player:           ^Player,
	texture:          rl.Texture,
}

drops_manager_create :: proc() -> ^DropsManager {
	dm := new(DropsManager)

	img := rl.LoadImage("assets/sprites/drops.png")
	defer rl.UnloadImage(img)

	dm.texture = rl.LoadTextureFromImage(img)

	return dm
}

drops_manager_setup :: proc(using self: ^DropsManager, bundle: ^ManagerBundle) {
	player = bundle.player
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
	col_items[new_index].has_arrows = drop_has_arrows[type]
	col_items[new_index].despawn_timer = timer_create(drop_despawn_time)
}

drops_manager_rng_drop :: proc(
	using self: ^DropsManager,
	types: bit_set[DropsType],
	position: rl.Vector2,
) {
	for t in DropsType {
		if t not_in types {
			continue
		}

		if !chance_was_successful(drop_chance[t]) {
			return
		}

		drops_manager_spawn(self, t, position)
	}
}

drops_manager_update :: proc(using self: ^DropsManager, dt: f32) {
	for i in 0 ..< col_index {
		if !col_items[i].alive {
			continue
		}

		timer_update(&col_items[i].despawn_timer, dt)

		if col_items[i].despawn_timer.finished {
			drops_manager_kill(self, DropId(i))
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
	arrows := 0

	for i in 0 ..< col_index {
		if !col_items[i].alive {
			continue
		}

		rl.DrawTexturePro(
			texture,
			{col_items[i].type == .Health ? 8.0 : 0.0, 0.0, 8.0, 8.0},
			{col_items[i].position.x, col_items[i].position.y, 8.0, 8.0},
			{0, 0},
			0.0,
			rl.WHITE,
		)

		if col_items[i].has_arrows && arrows < drop_max_arrows {
			from := player.position
			to := col_items[i].position
			line := linalg.normalize(to - from)

			if linalg.distance(from, to) < drop_arrow_offset * 2 {
				continue
			}

			rl.DrawLineEx(
				from + line * drop_arrow_offset,
				to - line * drop_arrow_offset,
				0.5,
				rl.GREEN,
			)

			arrows += 1
		}
	}
}

drops_manager_kill :: proc(using self: ^DropsManager, drop: DropId) {
	col_free_id(&self.collection, drop)
}

drops_manager_reset :: proc(using self: ^DropsManager) {
	col_index = 0
	col_count = 0

	for &item in col_items {
		item.alive = false
	}
}

drops_manager_destroy :: proc(using self: ^DropsManager) {
	rl.UnloadTexture(texture)
	free(self)
}
