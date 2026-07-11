-- ═══════════════════════════════════════════════════════════
-- 📖  AURA DATABASE  —  ModuleScript   |   PLACE IN: ReplicatedStorage
-- ═══════════════════════════════════════════════════════════
-- 📝 WHAT IT DOES (simple words):
-- The "dictionary" of every aura in your game. Each entry has a
-- Name, a Rarity (1 in X chance), a Color, and a Tier label.
-- Both the SERVER (when rolling) and the CLIENT (when animating
-- and showing the result) read this same list.
--
-- 🎨 HOW TO CUSTOMIZE:
--   • ADD an aura    → copy one { } block, fill it in
--   • REMOVE an aura → delete its { } block
--   • MAKE rarer/cheaper → change the Rarity number (higher = rarer)
--   • Tier is just a label shown in the UI (Common/Rare/Mythic...)
--
-- 🔗 RELATED SCRIPTS:
--   • RollServer → calls AuraData.GetWeightedRandom() to pick a winner
--   • RollUI     → reads AuraData.Auras for the flicker animation + colors
--
-- 💡 SUGGESTION / EXAMPLE ADDITION:
--   Add a "Description" field to show lore under the aura name:
--   { Name = "Nine-Tails", Rarity = 5000, Color = Color3.fromRGB(255,120,40),
--     Tier = "Legendary", Description = "Sealed beast chakra" }
-- ═══════════════════════════════════════════════════════════

local AuraData = {}

-- ⚙️ ─────────────── CUSTOMIZE: YOUR AURAS LIVE HERE ───────────────
AuraData.Auras = {

	-- ────── GENERIC POWER TIERS ──────
	{ Name = "Flicker",  Rarity = 1,      Color = Color3.fromRGB(180,180,180), Tier = "Common"    },
	{ Name = "Spark",    Rarity = 4,      Color = Color3.fromRGB(120,200,255), Tier = "Common"    },
	{ Name = "Glow",     Rarity = 16,     Color = Color3.fromRGB(120,255,150), Tier = "Uncommon"  },
	{ Name = "Ember",    Rarity = 32,     Color = Color3.fromRGB(255,140,60),  Tier = "Uncommon"  },
	{ Name = "Surge",    Rarity = 128,    Color = Color3.fromRGB(80,120,255),  Tier = "Rare"      },
	{ Name = "Bloom",    Rarity = 256,    Color = Color3.fromRGB(255,90,200),  Tier = "Rare"      },
	{ Name = "Tempest",  Rarity = 1000,   Color = Color3.fromRGB(0,255,200),   Tier = "Epic"      },
	{ Name = "Eclipse",  Rarity = 7777,   Color = Color3.fromRGB(20,20,40),    Tier = "Legendary" },
	{ Name = "Genesis",  Rarity = 70000,  Color = Color3.fromRGB(255,255,200), Tier = "Mythic"    },

	-- ────── ANIME-INSPIRED MIX ──────
	{ Name = "Spirit Bomb",    Rarity = 500,   Color = Color3.fromRGB(80,160,255),  Tier = "Rare"      },
	{ Name = "Nine-Tails",     Rarity = 5000,  Color = Color3.fromRGB(255,120,40),  Tier = "Legendary" },
	{ Name = "Conqueror Haki", Rarity = 8000,  Color = Color3.fromRGB(200,0,0),     Tier = "Legendary" },
	{ Name = "Cursed Energy",  Rarity = 12000, Color = Color3.fromRGB(60,0,90),     Tier = "Mythic"    },
	{ Name = "Hollow Mask",    Rarity = 20000, Color = Color3.fromRGB(245,245,245), Tier = "Mythic"    },
}
-- ⚙️ ────────────────────── END CUSTOMIZE ────────────────────────

local function rollOnce()
	local totalWeight = 0
	for _, aura in ipairs(AuraData.Auras) do
		totalWeight = totalWeight + 1 / aura.Rarity
	end
	local r = math.random() * totalWeight
	local cumulative = 0
	for _, aura in ipairs(AuraData.Auras) do
		cumulative = cumulative + 1 / aura.Rarity
		if r <= cumulative then
			return aura
		end
	end
	return AuraData.Auras[1]
end

function AuraData.GetWeightedRandom(luck)
	luck = math.max(1, math.floor(luck or 1))
	local best = rollOnce()
	for _ = 2, luck do
		local attempt = rollOnce()
		if attempt.Rarity > best.Rarity then
			best = attempt
		end
	end
	return best
end

function AuraData.GetByName(name)
	for _, aura in ipairs(AuraData.Auras) do
		if aura.Name == name then
			return aura
		end
	end
	return nil
end

return AuraData
