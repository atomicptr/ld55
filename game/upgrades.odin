package game

import "core:math/rand"

Upgrade :: enum u8 {
	PlusHealth,
	PlusMaxHealth,
	BigPlusMaxHealth,
	RestoreAllHealth,
	SpawnMinionShooter,
	Iframe,
	FreezeTimeShort,
	FreezeTimeMid,
	FreezeTimeLong,
	SpawnMultipleShooter,
}

Rarity :: enum u8 {
	Common,
	Rare,
	Epic,
}

rarity_chance := [Rarity]f32 {
	.Common = 0.8,
	.Rare   = 0.15,
	.Epic   = 0.05,
}

UpgradeStats :: struct {
	description: cstring,
	value:       uint,
	rarity:      Rarity,
	format:      bool,
}

upgrade_stats := [Upgrade]UpgradeStats {
	.PlusHealth = {description = "Restore +%d Health", value = 1, rarity = .Common, format = true},
	.PlusMaxHealth =  {
		description = "Increase +%d Max Health",
		value = 1,
		rarity = .Rare,
		format = true,
	},
	.BigPlusMaxHealth =  {
		description = "Increase +%d Max Health",
		value = 3,
		rarity = .Rare,
		format = true,
	},
	.RestoreAllHealth =  {
		description = "Completely restore Health",
		value = 0,
		rarity = .Rare,
		format = false,
	},
	.SpawnMinionShooter =  {
		description = "Summon Shooter Minion",
		value = 1,
		rarity = .Rare,
		format = false,
	},
	.Iframe =  {
		description = "Player becomes\ninvulnerable for %d seconds",
		value = 5,
		rarity = .Common,
		format = true,
	},
	.FreezeTimeShort =  {
		description = "ZA WARUDO:\nFreeze time for %d seconds",
		value = 2,
		rarity = .Common,
		format = true,
	},
	.FreezeTimeMid =  {
		description = "ZA WARUDO:\nFreeze time for %d seconds",
		value = 5,
		rarity = .Rare,
		format = true,
	},
	.FreezeTimeLong =  {
		description = "ZA WARUDO:\nFreeze time for %d seconds",
		value = 10,
		rarity = .Epic,
		format = true,
	},
	.SpawnMultipleShooter = {
		description = "Spawn %d Shooter Minions",
		value = 3,
		rarity = .Epic,
		format = true,
	}
}

roll_upgrade :: proc(exclude: bit_set[Upgrade]) -> Upgrade {
	rarity: Rarity =
		chance_was_successful(rarity_chance[.Epic]) \
		? .Epic \
		: chance_was_successful(rarity_chance[.Rare]) ? .Rare : .Common

	u: Upgrade = .PlusHealth

	for i in 0 ..= rand.uint32() {
		upgrade := Upgrade(i % (u32(max(Upgrade)) + 1))

		if upgrade in exclude {
			continue
		}

		if upgrade_stats[upgrade].rarity != rarity {
			continue
		}

		u = upgrade
	}

	return u
}
