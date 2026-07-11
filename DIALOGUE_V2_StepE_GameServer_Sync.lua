-- ═══════════════════════════════════════════════════════════
-- 🔌  STEP E (OPTIONAL) — GAME SERVER ↔ SHOPDATA SYNC CHECK
-- Paste in:  View ▸ Command Bar   →   Enter
-- ═══════════════════════════════════════════════════════════
-- 📝 WHAT THIS DOES (READ-ONLY + SAFE):
--   It looks at your GameServer script and tells you whether it
--   already pulls shop items from ShopData. If not, it prints the
--   EXACT one line to change so that adding a potion in ShopData
--   is the only edit you ever need (purchase works automatically).
--   It does NOT modify anything on its own — it just diagnoses.
-- ═══════════════════════════════════════════════════════════

local SSS = game:GetService("ServerScriptService")
local RS  = game:GetService("ReplicatedStorage")

print("═══════════════════════════════════════════════")
print("🔌  GAME SERVER ↔ SHOPDATA SYNC CHECK")
print("═══════════════════════════════════════════════")

-- 1) Make sure ShopData exists
local shopData = RS:FindFirstChild("ShopData")
if not shopData then
	warn("❌ ShopData module not found! Run Step A first.")
	return
end
print("✅ ShopData module found in ReplicatedStorage.")

-- 2) Find the GameServer script
local gameServer = SSS:FindFirstChild("GameServer")
if not gameServer then
	-- try common alternate locations/names
	for _, n in ipairs({ "GameServer", "RNGManager", "MainServer" }) do
		local s = SSS:FindFirstChild(n)
		if s and s:IsA("Script") then gameServer = s break end
	end
end
if not gameServer then
	warn("❌ Couldn't find a GameServer script in ServerScriptService.")
	warn("   Open your main server script manually and follow the note below.")
else
	print("✅ Found server script: " .. gameServer:GetFullName())
end

-- 3) Inspect its source (read-only)
local src = gameServer and gameServer.Source or ""
local hasHardcoded  = string.find(src, 'SHOP_ITEMS%s*=%s*%[%s*\n') ~= nil
                    or string.find(src, 'SHOP_ITEMS%s*=%s*%{') ~= nil
local usesShopData  = string.find(src, 'require%(.-ShopData.+%)%.Items') ~= nil
                    or string.find(src, 'ShopData.+%.Items') ~= nil

print("")
if usesShopData then
	print("🎉 ALREADY SYNCED! Your GameServer pulls items from ShopData.")
	print("   Adding a potion in ShopData is all you need. 🚀")
elseif hasHardcoded then
	print("⚠️  Your GameServer has a HARDCODED SHOP_ITEMS table.")
	print("   To make potions work from ONE place, open the GameServer Script")
	print("   and replace this line:")
	print("")
	print('       local SHOP_ITEMS = {')
	print('           ["LuckPotion"] = { ... },')
	print('           ["CoinBoost"]  = { ... },')
	print('           ...')
	print('       }')
	print("")
	print("   ...with this single line:")
	print("")
	print('       local SHOP_ITEMS = require(ReplicatedStorage:WaitForChild("ShopData")).Items')
	print("")
	print("   ✅ That's it! ShopData now owns all items (price, duration, type, value).")
	print("   (ShopData already includes every field the server needs: Price, Duration, Type, Value.)")
else
	print("ℹ️  Couldn't auto-detect a SHOP_ITEMS table in GameServer.")
	print("   If your shop logic uses a different variable name, just point it at:")
	print('       require(ReplicatedStorage:WaitForChild("ShopData")).Items')
end

-- 4) List the items ShopData currently offers (so you can compare)
print("")
print("📦 ShopData currently offers these items:")
local m = require(shopData)
local count = 0
for id, item in pairs(m.Items or {}) do
	count = count + 1
	print(string.format("   • %-14s %-22s %8d coins  [%s]",
		id, item.DisplayName or "?", item.Price or 0, item.Type or "?"))
end
if count == 0 then
	warn("   (no items defined — add some in ShopData.Items!)")
end
print("")
print("═══════════════════════════════════════════════")
