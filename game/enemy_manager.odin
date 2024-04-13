package game

import "core:fmt"
import "core:math/linalg"
import "core:math/rand"
import rl "libs:raylib"

enemies_max :: 1028

enemy_acceleration_min :: 1.0
enemy_acceleration_max :: 3.0

EnemyType :: enum {
	Grunt,
}

Enemy :: struct {
	id:           uint,
	type:         EnemyType,
	alive:        bool,
	position:     rl.Vector2,
	velocity:     rl.Vector2,
	acceleration: f32,
}

EnemyManager :: struct {
	player:      ^Player,
	enemies:     #soa[enemies_max]Enemy,
	enemy_index: uint,
}

enemy_manager_create :: proc(player: ^Player) -> ^EnemyManager {
	em := new(EnemyManager)
	em.player = player
	em.enemy_index = 0
	return em
}

enemy_spawn :: proc(using self: ^EnemyManager, type: EnemyType, position: rl.Vector2) {
	if enemy_index >= enemies_max {
		return
	}

	enemies[enemy_index] = Enemy {
		enemy_index,
		type,
		true,
		position,
		{0, 0},
		rand.float32_range(enemy_acceleration_min, enemy_acceleration_max),
	}
	enemy_index += 1
}

boids :: proc(using self: ^EnemyManager, me: uint) -> rl.Vector2 {
	return boids_rule1(self, me) + boids_rule2(self, me) + boids_rule3(self, me)
}

boids_rule1 :: proc(using self: ^EnemyManager, me: uint) -> rl.Vector2 {
	sum := rl.Vector2(0)

	for i in 0 ..< enemy_index {
		if me == uint(i) {
			continue
		}
		sum += enemies[enemy_index].position
	}

	center_of_mass := sum / f32(enemy_index - 1)

	return direction_to(enemies[me].position, center_of_mass) / 100
}

boids_rule2 :: proc(using self: ^EnemyManager, me: uint) -> rl.Vector2 {
	threshold :: 15.0

	c := rl.Vector2(0)

	for i in 0 ..< enemy_index {
		if me == uint(i) {
			continue
		}

		if linalg.length(enemies[i].position - enemies[me].position) < threshold {
			c -= enemies[i].position - enemies[me].position
		}
	}

	return c
}

boids_rule3 :: proc(using self: ^EnemyManager, me: uint) -> rl.Vector2 {
	vel := rl.Vector2(0)

	for i in 0 ..< enemy_index {
		if me == uint(i) {
			continue
		}

		vel += enemies[enemy_index].velocity
	}

	vel /= f32(enemy_index - 1)

	return (vel - enemies[enemy_index].velocity) / 8
}

enemy_manager_update :: proc(using self: ^EnemyManager, dt: f32) {
	for i in 0 ..< enemy_index {
		boids_vec := boids(self, enemies[i].id)

		direction := direction_to(enemies[i].position, player.position) + boids_vec

		enemies[i].velocity = rl.Vector2MoveTowards(
			enemies[i].velocity,
			direction,
			enemies[i].acceleration * dt,
		)
		// enemies[i].velocity += boids_vec
		enemies[i].position += enemies[i].velocity
	}
}

enemy_manager_draw :: proc(using self: ^EnemyManager) {
	for i in 0 ..< enemy_index {
		enemy := &enemies[i]

		rl.DrawRectangleRec({enemy.position.x, enemy.position.y, 8, 8}, rl.RED)
		rl.DrawLine(
			i32(enemy.position.x + 4),
			i32(enemy.position.y + 4),
			i32(enemy.position.x + 4 + enemy.velocity.x * 10),
			i32(enemy.position.y + 4 + enemy.velocity.y * 10),
			rl.GREEN,
		)
	}
}

enemy_manager_destroy :: proc(self: ^EnemyManager) {
	free(self)
}
