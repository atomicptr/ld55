package game

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import rl "libs:raylib"

enemies_max :: 2048

enemy_acceleration_min :: 1.0
enemy_acceleration_max :: 4.0
enemy_iframe_duration :: 1.0
enemy_shoot_cooldown :: 0.5
boss_shoot_cooldown :: 0.25

EnemyType :: enum {
	Grunt,
	Shooter,
	Boss,
}

EnemyId :: distinct uint

enemy_type_max_hp := [EnemyType]uint {
	.Grunt   = 1,
	.Shooter = 3,
	.Boss    = 9,
}

enemy_type_size := [EnemyType]uint {
	.Grunt   = 8,
	.Shooter = 12,
	.Boss    = 32,
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
	shoot_timer:   Timer,
}

EnemyManager :: struct {
	using collection: Collection(EnemyId, Enemy, enemies_max),
	player:           ^Player,
	pm:               ^ProjectileManager,
}

enemy_manager_create :: proc() -> ^EnemyManager {
	em := new(EnemyManager)
	return em
}

enemy_manager_setup :: proc(using self: ^EnemyManager, bundle: ^ManagerBundle) {
	player = bundle.player
	pm = bundle.pm
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
	col_items[new_index].size = enemy_type_size[type]
	col_items[new_index].acceleration = rand.float32_range(
		enemy_acceleration_min,
		enemy_acceleration_max,
	)
	col_items[new_index].health = enemy_type_max_hp[type]
	col_items[new_index].iframe_active = false
	col_items[new_index].iframe = timer_create(enemy_iframe_duration, false)
	col_items[new_index].shoot_timer = timer_create(
		type == .Boss ? boss_shoot_cooldown : enemy_shoot_cooldown,
		false,
	)
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

		// Do type specific logic
		switch col_items[i].type {
		case .Grunt:
			enemy_manager_process_grunt(self, EnemyId(i), dt)
		case .Shooter:
			enemy_manager_process_shooter(self, EnemyId(i), dt)
		case .Boss:
			enemy_manager_process_boss(self, EnemyId(i), dt)
		}

		col_items[i].position += col_items[i].velocity
	}
}

enemy_manager_process_grunt :: proc(using self: ^EnemyManager, i: EnemyId, dt: f32) {
	boids_vec := boids(&self.collection, col_items[i].id, {20.0, nil})

	direction := direction_to(col_items[i].position, player.position) + boids_vec

	col_items[i].velocity = rl.Vector2MoveTowards(
		col_items[i].velocity,
		direction,
		col_items[i].acceleration * dt,
	)
}

enemy_manager_process_shooter :: proc(using self: ^EnemyManager, i: EnemyId, dt: f32) {
	timer_update(&col_items[i].shoot_timer, dt)

	if linalg.distance(player.position, col_items[i].position) > 200.0 {
		enemy_manager_process_grunt(self, i, dt)
		return
	}

	if !col_items[i].shoot_timer.finished {
		return
	}

	player_pos := player.position + {f32(player_size) / 2, f32(player_size) / 2}
	player_vel := player.velocity

	aim_delta_time := aim_ahead(
		player_pos,
		col_items[i].position,
		player_vel,
		player.velocity,
		projectile_speed,
	)

	projectile_manager_shoot(
		pm,
		col_items[i].position,
		direction_to(col_items[i].position, player_pos + player_vel * aim_delta_time),
		projectile_speed,
		false,
	)

	timer_reset(&col_items[i].shoot_timer)
}

enemy_manager_process_boss :: proc(using self: ^EnemyManager, i: EnemyId, dt: f32) {
	timer_update(&col_items[i].shoot_timer, dt)

	if linalg.distance(player.position, col_items[i].position) > 250.0 {
		direction := direction_to(col_items[i].position, player.position)

		col_items[i].velocity = rl.Vector2MoveTowards(
			col_items[i].velocity,
			direction,
			col_items[i].acceleration * dt,
		)
		return
	}

	if col_items[i].shoot_timer.finished {
		col_items[i].velocity = {0, 0}

		player_pos := player.position + {f32(player_size) / 2, f32(player_size) / 2}
		player_vel := player.velocity

		aim_delta_time := aim_ahead(
			player_pos,
			col_items[i].position,
			player_vel,
			player.velocity,
			projectile_speed,
		)

		projectile_manager_shoot(
			pm,
			col_items[i].position,
			direction_to(col_items[i].position, player_pos + player_vel * aim_delta_time),
			projectile_speed / 2,
			false,
			8.0,
		)

		timer_reset(&col_items[i].shoot_timer)
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
	broker_post(
		b,
		.EnemyDied,
		EnemyDiedMsg{col_items[enemy_id].position, col_items[enemy_id].type},
	)
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
