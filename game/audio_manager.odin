package game

import rl "libs:raylib"

effect_volume :: 0.2

AudioEffect :: enum u8 {
	EffectZaWarudo,
}

AudioManager :: struct {
	effects: [AudioEffect]rl.Sound,
}

audio_manager_create :: proc() -> ^AudioManager {
	am := new(AudioManager)

	am.effects = {
		.EffectZaWarudo = rl.LoadSound("assets/sounds/zawarudo.wav"),
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
