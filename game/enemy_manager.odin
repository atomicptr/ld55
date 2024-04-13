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
	player:      ^Player,
	enemies:     #soa[enemies_max]Enemy,
	enemy_index: uint,
	count:       uint,
}

enemy_manager_create :: proc(player: ^Player) -> ^EnemyManager {
	em := new(EnemyManager)
	em.player = player
	em.enemy_index = 0
	return em
}

enemy_spawn :: proc(using self: ^EnemyManager, type: EnemyType, position: rl.Vector2) {
	// find free index
	reused_index := false
	index := enemy_index

	for i in 0 ..< enemy_index {
		if !enemies[i].alive {
			reused_index = true
			index = i
			break
		}
	}

	if index == enemy_index && enemy_index >= enemies_max {
		return
	}

	// TODO: depending on type define size and speed

	enemies[index] = Enemy {
		EnemyId(index),
		type,
		true,
		position,
		{0, 0},
		rand.float32_range(enemy_acceleration_min, enemy_acceleration_max),
		8,
	}

	if !reused_index {
		enemy_index += 1
	}

	count += 1
}

boids :: proc(using self: ^EnemyManager, me: EnemyId) -> rl.Vector2 {
	return boids_rule1(self, me) + boids_rule2(self, me) + boids_rule3(self, me)
}

boids_rule1 :: proc(using self: ^EnemyManager, me: EnemyId) -> rl.Vector2 {
	sum := rl.Vector2(0)

	for i in 0 ..< enemy_index {
		if me == EnemyId(i) || !enemies[i].alive {
			continue
		}

		sum += enemies[i].position
	}

	center_of_mass := sum / f32(count)

	return direction_to(enemies[me].position, center_of_mass) / 100
}

boids_rule2 :: proc(using self: ^EnemyManager, me: EnemyId) -> rl.Vector2 {
	threshold :: 15.0

	c := rl.Vector2(0)

	for i in 0 ..< enemy_index {
		if me == EnemyId(i) || !enemies[i].alive {
			continue
		}

		if linalg.length(enemies[i].position - enemies[me].position) < threshold {
			c -= enemies[i].position - enemies[me].position
		}
	}

	return c
}

boids_rule3 :: proc(using self: ^EnemyManager, me: EnemyId) -> rl.Vector2 {
	vel := rl.Vector2(0)

	for i in 0 ..< enemy_index {
		if me == EnemyId(i) || !enemies[i].alive {
			continue
		}

		vel += enemies[i].velocity
	}

	vel /= f32(count)

	return (vel - enemies[me].velocity) / 8
}

enemy_manager_update :: proc(using self: ^EnemyManager, dt: f32) {
	for i in 0 ..< enemy_index {
		if !enemies[i].alive {
			continue
		}

		// check if an enemy collides with player
		if rl.CheckCollisionRecs(
			    {
				   enemies[i].position.x,
				   enemies[i].position.y,
				   f32(enemies[i].size),
				   f32(enemies[i].size),
			   },
			   {player.position.x, player.position.y, player_size, player_size},
		   ) {
			broker_post(b, .PlayerGotHit, ByEnemyMsg{enemies[i]})
		}

		// update position
		boids_vec := boids(self, enemies[i].id)

		direction := direction_to(enemies[i].position, player.position) + boids_vec

		enemies[i].velocity = rl.Vector2MoveTowards(
			enemies[i].velocity,
			direction,
			enemies[i].acceleration * dt,
		)
		enemies[i].position += enemies[i].velocity
	}
}

enemy_manager_draw :: proc(using self: ^EnemyManager) {
	for i in 0 ..< enemy_index {
		if !enemies[i].alive {
			continue
		}

		enemy := &enemies[i]

		rl.DrawRectangleRec(
			{enemy.position.x, enemy.position.y, f32(enemies[i].size), f32(enemies[i].size)},
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
	enemies[enemy_id].alive = false
	count -= 1
}

enemy_manager_destroy :: proc(self: ^EnemyManager) {
	free(self)
}
