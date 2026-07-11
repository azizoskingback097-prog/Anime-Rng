-- ═══════════════════════════════════════════════════════════
-- 🔌  SYS2 #7b — SYNC GAME SERVER TO ShopData.GetServerItems()
-- Paste in:  View ▸ Command Bar   →   Enter   (run AFTER #2)
-- Edits:  ServerScriptService ▸ GameServer  (Source)
-- ═══════════════════════════════════════════════════════════
-- 📝 WHY: the canonical ShopData uses friendly fields (PriceCoins,
--    EffectType, Multiplier). The server's purchase logic reads
--    Price/Type/Value/Duration. GetServerItems() bridges them.
--    This patch makes the server charge whatever is in ShopData.
--
--    Handles 3 cases:  hardcoded table  |  .Items (old sync)  |  already done
-- ═══════════════════════════════════════════════════════════

local SSS = game:GetService("ServerScriptService")
local gs
for _, n in ipairs({ "GameServer", "RNGManager", "MainServer" }) do
	local s = SSS:FindFirstChild(n)
	if s and s:IsA("Script") and s.Source and s.Source ~= "" then gs = s break end
end
if not gs then warn("❌ No GameServer Script found. Nothing changed."); return end
print("🔌 Syncing shop prices in: " .. gs:GetFullName())

local src = gs.Source
local NEW = 'SHOP_ITEMS = require(ReplicatedStorage:WaitForChild("ShopData")).GetServerItems()'

-- Case 1: already using GetServerItems() -> done
if src:find("GetServerItems%(%)") then
	print("✅ Already synced to ShopData.GetServerItems(). Nothing to do!")
	return
end

-- Case 2: previously synced to .Items -> upgrade to .GetServerItems()
if src:find('SHOP_ITEMS%s*=%s*require.-ShopData.+%.Items') then
	src = src:gsub('(SHOP_ITEMS%s*=%s*require%([^)]-%)[:%.]WaitForChild%("ShopData"%)%)%.Items', '%1.GetServerItems()')
	-- fallback if the above didn't catch it
	if not src:find("GetServerItems%(%)") then
		src = src:gsub('(require%(ReplicatedStorage:WaitForChild%("ShopData"%)%)%.Items)', '%1.GetServerItems()')
	end
	gs.Source = src
	if src:find("GetServerItems%(%)") then
		print("✅ Upgraded .Items -> .GetServerItems(). Purchases now use canonical prices.")
	else
		warn("⚠️ Couldn't auto-upgrade. Manually change the SHOP_ITEMS line to:")
		print("   " .. NEW)
	end
	return
end

-- Case 3: hardcoded SHOP_ITEMS = { ... } -> replace via brace matching
local sMatch = src:find("SHOP_ITEMS%s*=%s*%{")
if sMatch then
	local eOpen = src:find("%{", sMatch)
	local function matchBrace(text, openPos)
		local depth = 0; local i = openPos; local inStr=false; local strCh
		while i <= #text do
			local c = text:sub(i,i)
			if inStr then if c==strCh then inStr=false end
			elseif c=='"' or c=="'" then inStr=true; strCh=c
			elseif c=="{" then depth=depth+1
			elseif c=="}" then depth=depth-1; if depth==0 then return i end end
			i=i+1
		end
		return nil
	end
	local close = matchBrace(src, eOpen)
	if close then
		src = src:sub(1, sMatch-1) .. NEW .. src:sub(close+1)
		gs.Source = src
		print("✅ Replaced hardcoded SHOP_ITEMS table with ShopData.GetServerItems().")
		return
	end
end

-- Case 4: nothing recognizable
print("ℹ️  No SHOP_ITEMS found in GameServer (your shop logic may live elsewhere).")
print("   To make the server charge ShopData prices, set your item table to:")
print("   " .. NEW)
