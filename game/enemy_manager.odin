package game

import "core:fmt"
import "core:math/linalg"
import rl "libs:raylib"

enemies_max :: 1028
enemy_acceleration :: 2.0

EnemyType :: enum {
	Grunt,
}

Enemy :: struct {
	type:     EnemyType,
	alive:    bool,
	position: rl.Vector2,
	velocity: rl.Vector2,
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

enemy_spawn :: proc(using self: ^EnemyManager, type: EnemyType) {
	if enemy_index >= enemies_max {
		return
	}

	enemies[enemy_index] = Enemy{type, true, {0, 0}, {0, 0}}
	enemy_index += 1
}

enemy_manager_update :: proc(using self: ^EnemyManager, dt: f32) {
	for &enemy in enemies {
		if !enemy.alive {
			continue
		}

		direction := direction_to(enemy.position, player.position)

		enemy.velocity = rl.Vector2MoveTowards(enemy.velocity, direction, enemy_acceleration * dt)
		enemy.position += enemy.velocity
	}
}

enemy_manager_draw :: proc(using self: ^EnemyManager) {
	for enemy in enemies {
		if !enemy.alive {
			continue
		}

		rl.DrawRectangleRec({enemy.position.x, enemy.position.y, 8, 8}, rl.RED)
	}
}

enemy_manager_destroy :: proc(self: ^EnemyManager) {
	free(self)
}
