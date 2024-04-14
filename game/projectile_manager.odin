package game

import "core:math/linalg"
import rl "libs:raylib"

projectiles_max :: 4096
projectile_max_range :: 500.0
projectile_size :: 4
projectile_timer_threshold :: 5.0
projectile_speed :: 200.0

ProjectileId :: distinct uint

Projectile :: struct {
	id:             ProjectileId,
	position:       rl.Vector2,
	direction:      rl.Vector2,
	speed:          f32,
	shot_by_player: bool,
	alive:          bool,
	color:          rl.Color,
	timer:          Timer,
}

ProjectileManager :: struct {
	using collection: Collection(ProjectileId, Projectile, projectiles_max),
	player:           ^Player,
	em:               ^EnemyManager,
}

projectile_manager_create :: proc(
	player: ^Player,
	enemy_manager: ^EnemyManager,
) -> ^ProjectileManager {
	pm := new(ProjectileManager)
	pm.player = player
	pm.em = enemy_manager

	return pm
}

projectile_manager_shoot :: proc(
	using self: ^ProjectileManager,
	from: rl.Vector2,
	direction: rl.Vector2,
	speed: f32,
	shot_by_player: bool,
) {
	new_index, ok := col_new_id(&self.collection)
	if !ok {
		return
	}

	col_items[new_index] = Projectile {
		ProjectileId(new_index),
		from,
		linalg.normalize(direction),
		speed,
		shot_by_player,
		true,
		shot_by_player ? rl.BLUE : rl.PURPLE,
		timer_create(projectile_timer_threshold, true),
	}
}

projectile_manager_update :: proc(using self: ^ProjectileManager, dt: f32) {
	for i in 0 ..< col_index {
		if !col_items[i].alive {
			continue
		}

		timer_update(&col_items[i].timer, dt)

		if col_items[i].timer.finished {
			projectile_manager_kill(self, i)
			return
		}

		has_collided, enemy_id := is_colliding(self, ProjectileId(i))
		if has_collided {
			if col_items[i].shot_by_player {
				broker_post(b, .EnemyGotHit, EnemyMsg{enemy_id})
			} else {
				broker_post(b, .PlayerGotHit, EmptyMsg{})
			}

			projectile_manager_kill(self, i)
			return
		}

		col_items[i].position += col_items[i].direction * col_items[i].speed * dt
	}
}

projectile_manager_draw :: proc(using self: ^ProjectileManager) {
	for i in 0 ..< col_index {
		if !col_items[i].alive {
			continue
		}

		rl.DrawRectangleRec(
			{col_items[i].position.x, col_items[i].position.y, projectile_size, projectile_size},
			col_items[i].color,
		)
	}
}

@(private = "file")
projectile_manager_kill :: proc(using self: ^ProjectileManager, projectile: ProjectileId) {
	col_free_id(&self.collection, projectile)
}

@(private = "file")
is_colliding :: proc(using self: ^ProjectileManager, projectile: ProjectileId) -> (bool, EnemyId) {
	p := col_items[projectile]

	if !p.shot_by_player {
		return rl.CheckCollisionRecs(
			{p.position.x, p.position.y, projectile_size, projectile_size},
			{player.position.x, player.position.y, player_size, player_size},
		), EnemyId(0)
	}

	return enemy_manager_is_colliding(
		em,
		{p.position.x, p.position.y, projectile_size, projectile_size},
	)
}

projectile_manager_reset :: proc(using self: ^ProjectileManager) {
	col_index = 0
	col_count = 0

	for &item in col_items {
		item.alive = false
	}
}

projectile_manager_destroy :: proc(using self: ^ProjectileManager) {
	free(self)
}
