-- ═══════════════════════════════════════════════════════════
-- 🚨  CRITICAL FIX — ROLL TIMEOUT  (run this FIRST!)
-- Paste in:  View ▸ Command Bar   →   Enter
-- Overwrites:  ReplicatedStorage ▸ AuraData  (ModuleScript)
-- ═══════════════════════════════════════════════════════════
-- 🐛 THE BUG:
--   Your output showed: "Script timeout: exhausted allowed execution time"
--   at AuraData GetWeightedRandom. This happens when `luck` is a HUGE number
--   (e.g. saved data or an admin SetLuck gone wrong), so the roll loop runs
--   billions of times and freezes the game.
--
-- ✅ THE FIX:
--   • A LUCK CAP (MAX_LUCK) so rolling can NEVER time out, no matter what.
--   • A bulletproof weighted algorithm that always terminates.
--   • A guard so total weight can never be 0.
-- ═══════════════════════════════════════════════════════════

local RS = game:GetService("ReplicatedStorage")
local old = RS:FindFirstChild("AuraData"); if old then old:Destroy() end
task.wait(0.1)

local m = Instance.new("ModuleScript")
m.Name = "AuraData"
m.Parent = RS
m.Source = [====[
local AuraData = {}

-- 📌 CUSTOMIZABLE SECTION: Aura List  (add/copy a block to add an aura)
--   Rarity = "1 in N" (higher = rarer). Color = shown in UI. Tier = label.
AuraData.Auras = {
	-- COMMON
	{ Name = "Flicker",  Rarity = 1,      Color = Color3.fromRGB(180,180,180), Tier = "Common"    },
	{ Name = "Spark",    Rarity = 4,      Color = Color3.fromRGB(120,200,255), Tier = "Common"    },
	-- UNCOMMON
	{ Name = "Glow",     Rarity = 16,     Color = Color3.fromRGB(120,255,150), Tier = "Uncommon"  },
	{ Name = "Ember",    Rarity = 32,     Color = Color3.fromRGB(255,140,60),  Tier = "Uncommon"  },
	-- RARE
	{ Name = "Surge",    Rarity = 128,    Color = Color3.fromRGB(80,120,255),  Tier = "Rare"      },
	{ Name = "Bloom",    Rarity = 256,    Color = Color3.fromRGB(255,90,200),  Tier = "Rare"      },
	{ Name = "Spirit Bomb",  Rarity = 500,    Color = Color3.fromRGB(80,160,255),  Tier = "Rare"   },
	-- EPIC
	{ Name = "Tempest",  Rarity = 1000,   Color = Color3.fromRGB(0,255,200),   Tier = "Epic"      },
	-- LEGENDARY
	{ Name = "Nine-Tails",     Rarity = 5000,  Color = Color3.fromRGB(255,120,40),  Tier = "Legendary" },
	{ Name = "Eclipse",        Rarity = 7777,  Color = Color3.fromRGB(20,20,40),    Tier = "Legendary" },
	{ Name = "Conqueror Haki", Rarity = 8000,  Color = Color3.fromRGB(200,0,0),     Tier = "Legendary" },
	-- MYTHIC
	{ Name = "Cursed Energy",  Rarity = 12000, Color = Color3.fromRGB(60,0,90),     Tier = "Mythic"    },
	{ Name = "Hollow Mask",    Rarity = 20000, Color = Color3.fromRGB(245,245,245), Tier = "Mythic"    },
	{ Name = "Genesis",        Rarity = 70000, Color = Color3.fromRGB(255,255,200), Tier = "Mythic"    },
}

-- 🛡️ SAFETY CAP: luck higher than this is clamped. Prevents ANY timeout.
-- 1000 rolls is instant (<1ms) yet far more than any player needs.
local MAX_LUCK = 1000

-- 🧠 ROLL ALGORITHM — bulletproof weighted pick (always terminates)
local function rollOnce()
	local totalWeight = 0
	for _, aura in ipairs(AuraData.Auras) do
		totalWeight = totalWeight + 1 / aura.Rarity
	end
	-- Guard: never divide by zero / never loop forever
	if totalWeight <= 0 then return AuraData.Auras[1] end
	local r = math.random() * totalWeight
	local cumulative = 0
	for _, aura in ipairs(AuraData.Auras) do
		cumulative = cumulative + 1 / aura.Rarity
		if r <= cumulative then
			return aura
		end
	end
	return AuraData.Auras[#AuraData.Auras]  -- final fallback (float rounding)
end

-- "luck" = roll this many times, keep the RAREST result. Capped for safety.
function AuraData.GetWeightedRandom(luck)
	luck = math.max(1, math.floor(tonumber(luck) or 1))
	if luck > MAX_LUCK then
		warn("⚠️ AuraData: luck was "..luck..", clamped to "..MAX_LUCK.." (prevents timeout)")
		luck = MAX_LUCK
	end
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
		if aura.Name == name then return aura end
	end
	return nil
end

return AuraData
]====]

print("✅✅ AURADATA FIXED! Rolling can no longer time out (MAX_LUCK = 1000).")
print("   🎲 Press Play and roll — it should work instantly now!")
