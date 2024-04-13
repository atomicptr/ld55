package game

import "core:fmt"
import "core:math/linalg"
import rl "libs:raylib"

minion_max :: 1024
minion_player_range_friction :: 200.0
minion_player_distance :: 50.0
minion_enemy_range :: 200.0
minion_shoot_cooldown :: 0.5

MinionId :: distinct uint

MinionType :: enum {
	Shooter,
}

Minion :: struct {
	id:          MinionId,
	alive:       bool,
	type:        MinionType,
	position:    rl.Vector2,
	velocity:    rl.Vector2,
	shoot_timer: Timer,
}

MinionManager :: struct {
	using collection: Collection(MinionId, Minion, minion_max),
	player:           ^Player,
	em:               ^EnemyManager,
	pm:               ^ProjectileManager,
}

minion_manager_create :: proc(
	player: ^Player,
	enemy_manager: ^EnemyManager,
	projectile_manager: ^ProjectileManager,
) -> ^MinionManager {
	mm := new(MinionManager)
	mm.player = player
	mm.em = enemy_manager
	mm.pm = projectile_manager
	return mm
}

minion_manager_spawn :: proc(using self: ^MinionManager, type: MinionType, position: rl.Vector2) {
	new_index, ok := col_new_id(&self.collection)
	if !ok {
		return
	}

	col_items[new_index].id = MinionId(new_index)
	col_items[new_index].position = position
	col_items[new_index].alive = true
	col_items[new_index].shoot_timer = timer_create(minion_shoot_cooldown, false)
}

minion_manager_update :: proc(using self: ^MinionManager, dt: f32) {
	for i in 0 ..< col_index {
		if !col_items[i].alive {
			continue
		}

		timer_update(&col_items[i].shoot_timer, dt)

		// TODO: go/stay near the player
		col_items[i].velocity = direction_to(col_items[i].position, player.position) * 100.0
		if linalg.distance(player.position, col_items[i].position) < minion_player_distance {
			col_items[i].velocity = rl.Vector2MoveTowards(
				col_items[i].velocity,
				rl.Vector2{0, 0},
				minion_player_range_friction,
			)
		}

		col_items[i].velocity += boids(&self.collection, col_items[i].id, {30.0, player.position})

		if col_items[i].shoot_timer.finished {
			// TODO: find target in area around (depending on type do different shit ig)
			found_enemy_nearby, enemy_id := enemy_manager_is_colliding(
				em,
				 {
					col_items[i].position.x - minion_enemy_range * 0.5,
					col_items[i].position.y - minion_enemy_range * 0.5,
					minion_enemy_range,
					minion_enemy_range,
				},
			)
			if found_enemy_nearby {
				enemy_pos :=
					em.col_items[i].position +
					{f32(em.col_items[i].size / 2), f32(em.col_items[i].size / 2)}
				enemy_vel := em.col_items[i].velocity

				aim_delta_time := aim_ahead(
					enemy_pos,
					col_items[i].position,
					enemy_vel,
					rl.Vector2ClampValue(col_items[i].velocity, 0.0, 100.0),
					100.0,
				)

				projectile_manager_shoot(
					pm,
					col_items[i].position,
					direction_to(col_items[i].position, enemy_pos + enemy_vel * aim_delta_time),
					100.0,
					true,
				)

				timer_reset(&col_items[i].shoot_timer)
			}
		}

		col_items[i].position += rl.Vector2ClampValue(col_items[i].velocity, 0.0, 100.0) * dt
	}
}

minion_manager_draw :: proc(using self: ^MinionManager) {
	for i in 0 ..< col_index {
		if !col_items[i].alive {
			continue
		}

		rl.DrawCircle(i32(col_items[i].position.x), i32(col_items[i].position.y), 4, rl.DARKGREEN)

		rl.DrawLine(
			i32(col_items[i].position.x + 2),
			i32(col_items[i].position.y + 2),
			i32(col_items[i].position.x + 2 + col_items[i].velocity.x),
			i32(col_items[i].position.y + 2 + col_items[i].velocity.y),
			rl.PINK,
		)
	}
}

minion_manager_destroy :: proc(using self: ^MinionManager) {
	free(self)
}
