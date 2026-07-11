-- ═══════════════════════════════════════════════════════════
-- 🛒  STEP A — SHOP DATA MODULE  (Single Source of Truth)
-- Paste in:  View ▸ Command Bar   →   Enter
-- Creates:  ReplicatedStorage ▸ ShopData  (ModuleScript)
-- ═══════════════════════════════════════════════════════════
-- 📝 WHAT THIS DOES:
--   This is the ONE place you define potions / shop items.
--   The NPC dialogue + the Shop UI both AUTO-READ this file.
--   Add a potion here → the NPC offers it automatically. ✨
--   (Same "auto-detect" idea as the VFX system!)
-- ═══════════════════════════════════════════════════════════

local RS = game:GetService("ReplicatedStorage")
local old = RS:FindFirstChild("ShopData"); if old then old:Destroy() end
task.wait(0.1)

local m = Instance.new("ModuleScript")
m.Name = "ShopData"
m.Parent = RS
m.Source = [====[
-- ═══════════════════════════════════════════════════════════
-- 🛒  SHOP DATA  —  ModuleScript  |  ReplicatedStorage
-- THE single source of truth for everything the shop sells.
-- The NPC dialogue + Shop UI auto-read this. Add an item → it shows up!
-- ═══════════════════════════════════════════════════════════

local ShopData = {}

--[[
═══════════════════════════════════════════════════════════
📌 CUSTOMIZABLE SECTION: SHOP ITEMS (potions, boosts, etc.)
═══════════════════════════════════════════════════════════

HOW TO ADD A NEW POTION  (it auto-shows in the dialogue!):
  1. Copy one whole block below
  2. Change the key  (e.g. "SpeedPotion")  and the fields
  3. Done! The NPC will offer it automatically. ✨

FIELDS:
  DisplayName : the text on the dialogue button
  Description : shown when you ask about it (optional)
  Icon        : emoji shown next to the name
  Color       : button accent color
  Price       : coins needed to buy it
  Duration    : how long the boost lasts (seconds)
  Type        : "LuckMultiplier"  OR  "CoinMultiplier"  (server reads this)
  Value       : the multiplier  (2.0 = x2)
  BuyLine     : line(s) the NPC says when you buy  (string or {table})

NOTE: for a NEW potion to actually WORK when bought, the server's
SHOP_ITEMS must know the same key. See DIALOGUE_V2_GUIDE.md
(Step E) for the 1-line GameServer change that makes ShopData the
only place you ever need to edit. 🚀
────────────────────────────────────────────────────────────
]]
ShopData.Items = {
	LuckPotion = {
		DisplayName = "x2 Luck Potion",
		Description = "Doubles your luck while rolling for 5 minutes. Great for hunting rare auras!",
		Icon = "🍀",
		Color = Color3.fromRGB(120, 200, 120),
		Price = 100000,
		Duration = 300,
		Type = "LuckMultiplier",
		Value = 2.0,
		BuyLine = { "Bottoms up! May the rare auras favor you! 🍀", "Luck be a lady tonight!", "Go get 'em, champ!" },
	},
	CoinBoost = {
		DisplayName = "x2 Coins Boost",
		Description = "Doubles every coin you earn for 5 minutes. Cha-ching!",
		Icon = "💰",
		Color = Color3.fromRGB(255, 200, 80),
		Price = 200000,
		Duration = 300,
		Type = "CoinMultiplier",
		Value = 2.0,
		BuyLine = { "Spend it wisely, friend! 💰", "Money money money!", "Don't spend it all at once!" },
	},
	-- ➕ ADD MORE POTIONS BELOW — they show up in the dialogue automatically!
	--[[  EXAMPLE (uncomment to use):
	SpeedPotion = {
		DisplayName = "x2 Luck Mega Potion",
		Description = "A legendary brew. Double luck for a full 10 minutes!",
		Icon = "⭐",
		Color = Color3.fromRGB(160, 120, 255),
		Price = 500000,
		Duration = 600,
		Type = "LuckMultiplier",
		Value = 2.0,
		BuyLine = { "Behold... the legendary brew! ⭐", "Few are worthy of this one." },
	},
	]]
}

return ShopData
]====]

print("✅ STEP A done! ShopData module created in ReplicatedStorage.")
print("   📦 Items registered: LuckPotion, CoinBoost (+ any you add!)")
