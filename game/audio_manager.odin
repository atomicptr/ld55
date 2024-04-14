package game

import rl "libs:raylib"

effect_volume :: 0.2

AudioEffect :: enum u8 {
	Pew,
	EnemyPew,
	EffectZaWarudo,
	EnemyGotHit,
	PlayerGotHit,
	Boon,
	Pickup,
}

AudioManager :: struct {
	effects: [AudioEffect]rl.Sound,
}

audio_manager_create :: proc() -> ^AudioManager {
	am := new(AudioManager)

	am.effects = {
		.Pew            = rl.LoadSound("assets/sounds/pew.wav"),
		.EnemyPew       = rl.LoadSound("assets/sounds/enemy_pew.wav"),
		.EffectZaWarudo = rl.LoadSound("assets/sounds/zawarudo.wav"),
		.EnemyGotHit    = rl.LoadSound("assets/sounds/ehit.wav"),
		.PlayerGotHit   = rl.LoadSound("assets/sounds/phit.wav"),
		.Boon           = rl.LoadSound("assets/sounds/boon.wav"),
		.Pickup         = rl.LoadSound("assets/sounds/pickup.wav"),
	}

	return am
}

audio_manager_setup :: proc(using self: ^AudioManager, bundle: ^ManagerBundle) {}

audio_manager_play :: proc(using self: ^AudioManager, effect: AudioEffect) {
	rl.PlaySound(effects[effect])
}

audio_manager_destroy :: proc(using self: ^AudioManager) {
	for effect in effects {
		rl.UnloadSound(effect)
	}

	free(self)
}
