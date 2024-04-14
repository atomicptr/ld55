package game

import rl "libs:raylib"

MessageType :: enum {
	PlayerGotHit,
	EnemyGotHit,
	PlayerDied,
	EnemyDied,
	DropPickup,
}

MessageData :: union {
	EmptyMsg,
	EnemyMsg,
	AtLocationMsg,
	EnemyDiedMsg,
	DropPickupMsg,
}

EmptyMsg :: struct {}

EnemyMsg :: struct {
	enemy: EnemyId,
}

AtLocationMsg :: struct {
	position: rl.Vector2,
}

EnemyDiedMsg :: struct {
	position: rl.Vector2,
	type:     EnemyType,
}

DropPickupMsg :: struct {
	type: DropsType,
}
