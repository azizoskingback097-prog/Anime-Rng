-- ═══════════════════════════════════════════════════════════
-- 🛒  SYS2 #2 — SHOP DATA (canonical, scalable fields)
-- Paste in:  View ▸ Command Bar   →   Enter
-- Overwrites:  ReplicatedStorage ▸ ShopData  (ModuleScript)
-- ═══════════════════════════════════════════════════════════
-- 📝 THE single source of truth for shop items. Add a block → it
--    shows in the dialogue + shop UI, AND the server charges the
--    right price (after the GameServer sync line points here).
--
--    Each item uses clean, documented fields (see below).
-- ═══════════════════════════════════════════════════════════

local RS = game:GetService("ReplicatedStorage")
local old = RS:FindFirstChild("ShopData"); if old then old:Destroy() end
task.wait(0.1)

local m = Instance.new("ModuleScript")
m.Name = "ShopData"
m.Parent = RS
m.Source = [====[
local ShopData = {}

--[[
═══════════════════════════════════════════════════════════
📌 CUSTOMIZABLE SECTION: SHOP ITEMS  (data-driven!)
═══════════════════════════════════════════════════════════
  Add a block → it auto-shows in the shop + NPC dialogue, and
  the server handles purchase (after the GameServer sync line).

  FIELDS (every item):
    Id              : unique key (server uses this to charge you)
    DisplayName     : text on buttons / buy confirmations
    Description     : flavor / info text under the name
    PriceCoins      : cost in coins  ← edit to rebalance
    DurationSeconds : how long the boost lasts
    EffectType      : "Luck"  OR  "Coins"   (what it boosts)
    Multiplier      : the boost amount (2 = x2)
    Icon            : emoji shown next to the name
    IconImageId     : optional decal/image asset id ("" = use emoji)
    Color           : accent color for the card/button
    BuyLine         : line(s) the NPC says when you buy

  HOW TO ADD A NEW POTION: copy one block, change the fields. Done!
────────────────────────────────────────────────────────────
]]
ShopData.Items = {
	LuckPotion = {
		Id              = "LuckPotion",
		DisplayName     = "x2 Luck Potion",
		Description     = "Doubles your luck while rolling for 5 minutes.",
		PriceCoins      = 10000,
		DurationSeconds = 300,
		EffectType      = "Luck",
		Multiplier      = 2.0,
		Icon            = "🍀",
		IconImageId     = "",
		Color           = Color3.fromRGB(120, 200, 120),
		BuyLine         = { "Bottoms up! May the rare auras favor you! 🍀", "Luck be a lady tonight!" },
	},
	CoinBoost = {
		Id              = "CoinBoost",
		DisplayName     = "x2 Coins Boost",
		Description     = "Doubles every coin you earn for 5 minutes.",
		PriceCoins      = 25000,
		DurationSeconds = 300,
		EffectType      = "Coins",
		Multiplier      = 2.0,
		Icon            = "💰",
		IconImageId     = "",
		Color           = Color3.fromRGB(255, 200, 80),
		BuyLine         = { "Spend it wisely, friend! 💰", "Don't spend it all at once!" },
	},
	-- ➕ ADD MORE ITEMS BELOW — they show up everywhere automatically!
	--[[  EXAMPLE (uncomment to use):
	MegaLuckPotion = {
		Id              = "MegaLuckPotion",
		DisplayName     = "x3 Luck Mega Potion",
		Description     = "A legendary brew. Triple luck for 10 minutes!",
		PriceCoins      = 75000,
		DurationSeconds = 600,
		EffectType      = "Luck",
		Multiplier      = 3.0,
		Icon            = "⭐",
		IconImageId     = "",
		Color           = Color3.fromRGB(160, 120, 255),
		BuyLine         = { "Behold... the legendary brew! ⭐", "Few are worthy." },
	},
	]]
}

-- ═══════════════════════════════════════════════════════════
-- 🔌 HELPERS (UIs + server read from here — don't edit unless adding new effect types)
-- ═══════════════════════════════════════════════════════════
-- maps a friendly EffectType to the server's internal boost key
local EFFECT_TO_BOOST = { Luck = "LuckMultiplier", Coins = "CoinMultiplier" }

-- Ordered list of display-ready items (cheapest first) for the Shop UI + dialogue
function ShopData.GetDisplayItems()
	local F = require(script.Parent:WaitForChild("NumberFormatter"))
	local list = {}
	for id, cfg in pairs(ShopData.Items) do
		table.insert(list, {
			Id          = cfg.Id or id,
			Name        = cfg.DisplayName or id,
			Description = cfg.Description or "",
			Price       = cfg.PriceCoins or 0,
			PriceText   = F.FormatNumber(cfg.PriceCoins or 0),
			Icon        = cfg.Icon or "🧪",
			IconImageId = cfg.IconImageId or "",
			Color       = cfg.Color or Color3.fromRGB(120,120,140),
		})
	end
	table.sort(list, function(a, b) return a.Price < b.Price end)
	return list
end

-- Dict the server uses to validate + charge + apply boosts.
-- Shape is compatible with the existing purchase logic:
--   { [id] = { Price, Duration, Type, Value, Name } }
function ShopData.GetServerItems()
	local out = {}
	for id, cfg in pairs(ShopData.Items) do
		out[id] = {
			Price    = cfg.PriceCoins or 0,
			Duration = cfg.DurationSeconds or 0,
			Type     = EFFECT_TO_BOOST[cfg.EffectType] or (cfg.EffectType .. "Multiplier"),
			Value    = cfg.Multiplier or 1,
			Name     = cfg.DisplayName or id,
		}
	end
	return out
end

-- back-compat: ShopData.Abbreviate delegates to the shared formatter
function ShopData.Abbreviate(n)
	return require(script.Parent:WaitForChild("NumberFormatter")).FormatNumber(n)
end

return ShopData
]====]

print("✅ ShopData (canonical) created. Items: LuckPotion, CoinBoost.")
print("   GetDisplayItems() and GetServerItems() ready for UIs + server.")
