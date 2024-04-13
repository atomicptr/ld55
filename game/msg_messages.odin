package game

MessageType :: enum {
	PlayerGotHit,
	EnemyGotHit,
	PlayerDied,
}

MessageData :: union {
	EmptyMsg,
	EnemyMsg,
}

EmptyMsg :: struct {}

EnemyMsg :: struct {
	enemy: EnemyId,
}
