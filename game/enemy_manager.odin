package game

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import rl "libs:raylib"

enemies_max :: 1024

enemy_acceleration_min :: 1.0
enemy_acceleration_max :: 3.0

EnemyType :: enum {
	Grunt,
}

EnemyId :: distinct uint

Enemy :: struct {
	id:           EnemyId,
	type:         EnemyType,
	alive:        bool,
	position:     rl.Vector2,
	velocity:     rl.Vector2,
	acceleration: f32,
	size:         uint,
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

	col_items[new_index] = Enemy {
		new_index,
		type,
		true,
		position,
		{0, 0},
		rand.float32_range(enemy_acceleration_min, enemy_acceleration_max),
		8,
	}
}

boids :: proc(using self: ^EnemyManager, me: EnemyId) -> rl.Vector2 {
	return boids_rule1(self, me) + boids_rule2(self, me) + boids_rule3(self, me)
}

boids_rule1 :: proc(using self: ^EnemyManager, me: EnemyId) -> rl.Vector2 {
	sum := rl.Vector2(0)

	for i in 0 ..< col_index {
		if me == EnemyId(i) || !col_items[i].alive {
			continue
		}

		sum += col_items[i].position
	}

	center_of_mass := sum / f32(col_count)

	return direction_to(col_items[me].position, center_of_mass) / 100
}

boids_rule2 :: proc(using self: ^EnemyManager, me: EnemyId) -> rl.Vector2 {
	threshold :: 15.0

	c := rl.Vector2(0)

	for i in 0 ..< col_index {
		if me == EnemyId(i) || !col_items[i].alive {
			continue
		}

		if linalg.length(col_items[i].position - col_items[me].position) < threshold {
			c -= col_items[i].position - col_items[me].position
		}
	}

	return c
}

boids_rule3 :: proc(using self: ^EnemyManager, me: EnemyId) -> rl.Vector2 {
	vel := rl.Vector2(0)

	for i in 0 ..< col_index {
		if me == EnemyId(i) || !col_items[i].alive {
			continue
		}

		vel += col_items[i].velocity
	}

	vel /= f32(col_count)

	return (vel - col_items[me].velocity) / 8
}

enemy_manager_update :: proc(using self: ^EnemyManager, dt: f32) {
	for i in 0 ..< col_index {
		if !col_items[i].alive {
			continue
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
		boids_vec := boids(self, col_items[i].id)

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
		rl.DrawLine(
			i32(enemy.position.x + f32(enemy.size) * 0.5),
			i32(enemy.position.y + f32(enemy.size) * 0.5),
			i32(enemy.position.x + f32(enemy.size) * 0.5 + enemy.velocity.x * 10),
			i32(enemy.position.y + f32(enemy.size) * 0.5 + enemy.velocity.y * 10),
			rl.GREEN,
		)
	}
}

enemy_manager_kill :: proc(using self: ^EnemyManager, enemy_id: EnemyId) {
	col_free_id(&self.collection, enemy_id)
}

enemy_manager_is_colliding :: proc(
	using self: ^EnemyManager,
	rect: rl.Rectangle,
) -> (
	bool,
	EnemyId,
) {
	for i in 0 ..< col_index {
		if !col_items[i].alive {
			continue
		}

		if linalg.length(
			   rl.Vector2{rect.x, rect.y} -
			   rl.Vector2{col_items[i].position.x, col_items[i].position.y},
		   ) <=
		   f32(col_items[i].size + projectile_size) {
			if rl.CheckCollisionRecs(
				   rect,
				    {
					   col_items[i].position.x,
					   col_items[i].position.y,
					   f32(col_items[i].size),
					   f32(col_items[i].size),
				   },
			   ) {
				return true, EnemyId(i)
			}
		}
	}

	return false, EnemyId(0)
}

enemy_manager_destroy :: proc(self: ^EnemyManager) {
	free(self)
}
