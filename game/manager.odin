package game

ManagerBundle :: struct {
	player: ^Player,
	em:     ^EnemyManager,
	mm:     ^MinionManager,
	dm:     ^DropsManager,
	pm:     ^ProjectileManager,
}
