-- ═══════════════════════════════════════════════════════════
-- 💰  ECONOMY STEP 1 — SHOP DATA  (Rebalanced + 1K Formatting)
-- Paste in:  View ▸ Command Bar   →   Enter
-- Overwrites:  ReplicatedStorage ▸ ShopData  (ModuleScript)
-- ═══════════════════════════════════════════════════════════
-- 📝 WHAT THIS DOES:
--   This is now the SINGLE SOURCE OF TRUTH for prices + number formatting.
--   • The dialogue, the Shop UI, and the GameServer all read FROM HERE.
--   • Change a Price here → updates everywhere automatically. 🪄
--   • ShopData.Abbreviate(n) turns 1000 → "1K", 1500000 → "1.5M", etc.
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
📌 CUSTOMIZABLE SECTION: SHOP ITEMS (potions, boosts)
═══════════════════════════════════════════════════════════
   Add a block → it shows in the dialogue + shop automatically,
   AND the server charges the right price (after Step 2 sync).

FIELDS:
  DisplayName / Name : text on buttons (Name = same, for the server)
  Description        : flavor / info text
  Icon               : emoji
  Color              : accent color
  Price              : coins needed  ← edit THIS to rebalance!
  Duration           : boost length (seconds)
  Type               : "LuckMultiplier" OR "CoinMultiplier"
  Value              : the multiplier (2.0 = x2)
  BuyLine            : line(s) the NPC says when you buy

💰 ECONOMY MATH (so you can tune with confidence):
  • Average roll pays ~60–80 coins (most are common auras).
  • A player actively rolling earns ~3,000–4,000 coins/minute.
  • So:  10,000 ≈ 3 min  •  25,000 ≈ 7 min  •  100,000 ≈ 30 min.
  Tweak the Price values below to make potions cheaper/costlier!
────────────────────────────────────────────────────────────
]]--
ShopData.Items = {
	LuckPotion = {
		DisplayName = "x2 Luck Potion",
		Name        = "x2 Luck Potion",
		Description = "Doubles your luck while rolling for 5 minutes.",
		Icon = "🍀",
		Color = Color3.fromRGB(120, 200, 120),
		Price = 10000,        -- was 100,000 ✨ rebalanced
		Duration = 300,
		Type = "LuckMultiplier",
		Value = 2.0,
		BuyLine = { "Bottoms up! May the rare auras favor you! 🍀", "Luck be a lady tonight!" },
	},
	CoinBoost = {
		DisplayName = "x2 Coins Boost",
		Name        = "x2 Coins Boost",
		Description = "Doubles every coin you earn for 5 minutes.",
		Icon = "💰",
		Color = Color3.fromRGB(255, 200, 80),
		Price = 25000,        -- was 200,000 ✨ rebalanced
		Duration = 300,
		Type = "CoinMultiplier",
		Value = 2.0,
		BuyLine = { "Spend it wisely, friend! 💰", "Don't spend it all at once!" },
	},
	-- ➕ ADD MORE POTIONS BELOW — they show up automatically everywhere!
}

--[[
═══════════════════════════════════════════════════════════
📌 NUMBER FORMATTER — turns big numbers short (1K, 1.5M, 2.3B...)
   Used by the dialogue, Shop UI, and Coin HUD so everything
   shows "10K" instead of "10,000".
═══════════════════════════════════════════════════════════
   Examples:  999→"999"  1000→"1K"  25000→"25K"  1500000→"1.5M"
]]--
function ShopData.Abbreviate(n)
	n = tonumber(n) or 0
	if n < 0 then return "-" .. ShopData.Abbreviate(-n) end
	n = math.floor(n)
	local suffixes = { "", "K", "M", "B", "T", "Qa", "Qi" }
	local i = 1
	while n >= 1000 and i < #suffixes do
		n = n / 1000
		i = i + 1
	end
	-- 2 decimals max, then chop trailing zeros / dot
	local s = string.format("%.2f", n):gsub("%.?0+$", "")
	return s .. suffixes[i]
end

return ShopData
]====]

print("✅ ShopData updated! Rebalanced prices + Abbreviate() added.")
print("   🍀 LuckPotion: 10,000  |  💰 CoinBoost: 25,000")
print("   🔢 Number format ready: 1000 → 1K, 1500000 → 1.5M")
print("   ⏭️  Now run ECON_02 (GameServer sync) so purchases match!")
