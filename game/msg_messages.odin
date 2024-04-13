package game

MessageType :: enum {
	PlayerGotHit,
	PlayerDied,
}

MessageData :: union {
	EmptyMsg,
	ByEnemyMsg,
}

EmptyMsg :: struct {}

ByEnemyMsg :: struct {
	by: Enemy,
}
