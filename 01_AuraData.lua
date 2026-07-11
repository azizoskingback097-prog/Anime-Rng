-- ═══════════════════════════════════════════════════════════
-- 📖  AURA DATA  —  ModuleScript   |   PLACE IN: ReplicatedStorage
-- ═══════════════════════════════════════════════════════════
-- 📝 WHAT IT DOES (simple words):
-- The "dictionary" of every aura. Each aura has a Name, Rarity
-- (1 in X chance), Color, and Tier label. Both server (rolling)
-- and client (UI/animation) read this same list.
--
-- 🎨 HOW TO CUSTOMIZE:
--   Just edit the Aura List section below — add/remove entries!
--
-- 🔗 RELATED SCRIPTS:
--   • GameServer  → calls GetWeightedRandom() to pick a winner
--   • RollUI      → reads aura names for the flicker animation
--   • InventoryUI → reads colors for item display
--   • AdminUI     → reads the list for "give aura" buttons
--
-- 💡 SUGGESTION:
--   Add a "Description" field for lore shown under the aura name.
-- ═══════════════════════════════════════════════════════════

local AuraData = {}

--[[
────────────────────────────────────────
📌 CUSTOMIZABLE SECTION: Aura List
HOW TO USE: Each { } block is one aura. Copy one to add a new aura.
  • Rarity = "1 in N". Higher N = harder to roll (rarer).
  • Color = shown in UI, inventory, and announcements.
  • Tier = label used for sorting (Common/Rare/Legendary/Mythic).
  • Order doesn't matter — they're sorted by rarity automatically.

EXAMPLE — adding a brand new aura:
  { Name = "Chidori", Rarity = 3000, Color = Color3.fromRGB(100,200,255), Tier = "Legendary" },

That's it! It automatically:
  ✅ Gets added to the roll pool (weighted by 1/Rarity)
  ✅ Shows in the flicker animation
  ✅ Appears in the admin "give aura" list
  ✅ Can be given mutated versions (Sandy Chidori, etc.)
────────────────────────────────────────
]]
AuraData.Auras = {

	-- ────── COMMON (1 in 1 to 1 in 50) ──────
	{ Name = "Flicker",  Rarity = 1,      Color = Color3.fromRGB(180,180,180), Tier = "Common"    },
	{ Name = "Spark",    Rarity = 4,      Color = Color3.fromRGB(120,200,255), Tier = "Common"    },

	-- ────── UNCOMMON (1 in 16 to 1 in 64) ──────
	{ Name = "Glow",     Rarity = 16,     Color = Color3.fromRGB(120,255,150), Tier = "Uncommon"  },
	{ Name = "Ember",    Rarity = 32,     Color = Color3.fromRGB(255,140,60),  Tier = "Uncommon"  },

	-- ────── RARE (1 in 100 to 1 in 999) ──────
	{ Name = "Surge",    Rarity = 128,    Color = Color3.fromRGB(80,120,255),  Tier = "Rare"      },
	{ Name = "Bloom",    Rarity = 256,    Color = Color3.fromRGB(255,90,200),  Tier = "Rare"      },
	{ Name = "Spirit Bomb",  Rarity = 500,    Color = Color3.fromRGB(80,160,255),  Tier = "Rare"   },

	-- ────── EPIC (1 in 1000 to 1 in 4999) ──────
	{ Name = "Tempest",  Rarity = 1000,   Color = Color3.fromRGB(0,255,200),   Tier = "Epic"      },

	-- ────── LEGENDARY (1 in 5000 to 1 in 9999) ──────
	{ Name = "Nine-Tails",     Rarity = 5000,  Color = Color3.fromRGB(255,120,40),  Tier = "Legendary" },
	{ Name = "Eclipse",        Rarity = 7777,  Color = Color3.fromRGB(20,20,40),    Tier = "Legendary" },
	{ Name = "Conqueror Haki", Rarity = 8000,  Color = Color3.fromRGB(200,0,0),     Tier = "Legendary" },

	-- ────── MYTHIC (1 in 10000+) ──────
	{ Name = "Cursed Energy",  Rarity = 12000, Color = Color3.fromRGB(60,0,90),     Tier = "Mythic"    },
	{ Name = "Hollow Mask",    Rarity = 20000, Color = Color3.fromRGB(245,245,245), Tier = "Mythic"    },
	{ Name = "Genesis",        Rarity = 70000, Color = Color3.fromRGB(255,255,200), Tier = "Mythic"    },
}
--[[
────────────────────────────────────────
📌 END OF AURA LIST
To remove an aura: delete its { } line.
To make something rarer: increase the Rarity number.
To change its color: edit the Color3.fromRGB(R, G, B) values.
────────────────────────────────────────
]]


-- ═══════════════════════════════════════════════════════════
-- 🧠 ROLL ALGORITHM (don't edit unless you know what you're doing)
-- Picks one aura at random, weighted by 1/Rarity.
-- "luck" = roll N times and keep the rarest result.
-- ═══════════════════════════════════════════════════════════
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
