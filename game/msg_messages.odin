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
	DropPickupMsg,
}

EmptyMsg :: struct {}

EnemyMsg :: struct {
	enemy: EnemyId,
}

AtLocationMsg :: struct {
	position: rl.Vector2,
}

DropPickupMsg :: struct {
	type: DropsType,
}
