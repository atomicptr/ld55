package game

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import rl "libs:raylib"

enemies_max :: 2048

enemy_acceleration_min :: 1.0
enemy_acceleration_max :: 3.0
enemy_iframe_duration :: 1.0

EnemyType :: enum {
	Grunt,
}

EnemyId :: distinct uint

enemy_type_max_hp := [EnemyType]uint {
	.Grunt = 1,
}

Enemy :: struct {
	id:            EnemyId,
	type:          EnemyType,
	alive:         bool,
	position:      rl.Vector2,
	velocity:      rl.Vector2,
	acceleration:  f32,
	size:          uint,
	health:        uint,
	iframe_active: bool,
	iframe:        Timer,
}

EnemyManager :: struct {
	using collection: Collection(EnemyId, Enemy, enemies_max),
	player:           ^Player,
}

enemy_manager_create :: proc(player: ^Player) -> ^EnemyManager {
	em := new(EnemyManager)
	em.player = player
	return em
}

enemy_spawn :: proc(using self: ^EnemyManager, type: EnemyType, position: rl.Vector2) {
	new_index, ok := col_new_id(&self.collection)
	if !ok {
		return
	}

	// TODO: depending on type define size and speed

	col_items[new_index].id = new_index
	col_items[new_index].type = type
	col_items[new_index].alive = true
	col_items[new_index].position = position
	col_items[new_index].velocity = {0, 0}
	col_items[new_index].size = 8 // size by type? image?
	col_items[new_index].acceleration = rand.float32_range(
		enemy_acceleration_min,
		enemy_acceleration_max,
	)
	col_items[new_index].health = enemy_type_max_hp[type]
	col_items[new_index].iframe_active = false
	col_items[new_index].iframe = timer_create(enemy_iframe_duration, false)

}

enemy_manager_update :: proc(using self: ^EnemyManager, dt: f32) {
	for i in 0 ..< col_index {
		if !col_items[i].alive {
			continue
		}

		if col_items[i].iframe.finished {
			col_items[i].iframe_active = false
		}

		// check if an enemy collides with player
		if rl.CheckCollisionRecs(
			    {
				   col_items[i].position.x,
				   col_items[i].position.y,
				   f32(col_items[i].size),
				   f32(col_items[i].size),
			   },
			   {player.position.x, player.position.y, player_size, player_size},
		   ) {
			broker_post(b, .PlayerGotHit, EnemyMsg{EnemyId(i)})
		}

		// update position
		boids_vec := boids(&self.collection, col_items[i].id, {20.0, nil})

		direction := direction_to(col_items[i].position, player.position) + boids_vec

		col_items[i].velocity = rl.Vector2MoveTowards(
			col_items[i].velocity,
			direction,
			col_items[i].acceleration * dt,
		)
		col_items[i].position += col_items[i].velocity
	}
}

enemy_manager_draw :: proc(using self: ^EnemyManager) {
	for i in 0 ..< col_index {
		if !col_items[i].alive {
			continue
		}

		enemy := &col_items[i]

		rl.DrawRectangleRec(
			{enemy.position.x, enemy.position.y, f32(col_items[i].size), f32(col_items[i].size)},
			rl.RED,
		)

		when ODIN_DEBUG {
			rl.DrawLine(
				i32(enemy.position.x + f32(enemy.size) * 0.5),
				i32(enemy.position.y + f32(enemy.size) * 0.5),
				i32(enemy.position.x + f32(enemy.size) * 0.5 + enemy.velocity.x * 10),
				i32(enemy.position.y + f32(enemy.size) * 0.5 + enemy.velocity.y * 10),
				rl.GREEN,
			)
		}
	}
}

enemy_manager_process_damage :: proc(
	using self: ^EnemyManager,
	enemy_id: EnemyId,
	damage_origin: rl.Vector2,
) {
	if col_items[enemy_id].iframe_active {
		return
	}

	if col_items[enemy_id].health <= 1 {
		enemy_manager_kill(self, enemy_id)
		return
	}

	col_items[enemy_id].health -= 1
	col_items[enemy_id].velocity += direction_to(damage_origin, col_items[enemy_id].position) * 2.0
	col_items[enemy_id].iframe_active = true
	timer_reset(&col_items[enemy_id].iframe)
}

enemy_manager_kill :: proc(using self: ^EnemyManager, enemy_id: EnemyId) {
	broker_post(b, .EnemyDied, AtLocationMsg{col_items[enemy_id].position})
	col_free_id(&self.collection, enemy_id)
}

enemy_manager_is_colliding :: proc(
	using self: ^EnemyManager,
	rect: rl.Rectangle,
) -> (
	bool,
	EnemyId,
) {
	id := EnemyId(0)
	dist := max(f32)

	for i in 0 ..< col_index {
		if !col_items[i].alive {
			continue
		}

		dist_to := linalg.distance(rl.Vector2{rect.x, rect.y}, col_items[i].position)

		if rl.CheckCollisionRecs(
			   rect,
			    {
				   col_items[i].position.x,
				   col_items[i].position.y,
				   f32(col_items[i].size),
				   f32(col_items[i].size),
			   },
		   ) {
			if dist_to < dist {
				dist = dist_to
				id = EnemyId(i)
			}

			// return true, EnemyId(i)

		}
	}

	if dist < max(f32) {
		return true, id
	}

	return false, EnemyId(0)
}

enemy_manager_reset :: proc(using self: ^EnemyManager) {
	col_index = 0
	col_count = 0

	for &item in col_items {
		item.alive = false
	}
}

enemy_manager_destroy :: proc(self: ^EnemyManager) {
	free(self)
}
