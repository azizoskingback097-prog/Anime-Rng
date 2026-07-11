-- ═══════════════════════════════════════════════════════════
-- 🔌  ECONOMY STEP 2 — SYNC GAME SERVER TO SHOPDATA
-- Paste in:  View ▸ Command Bar   →   Enter
-- ═══════════════════════════════════════════════════════════
-- 📝 WHAT THIS DOES:
--   Finds the SHOP_ITEMS table inside your GameServer and replaces it with
--   a single line that READS from ShopData. After this, you only ever edit
--   prices in ShopData — the server charges the exact same price. ✨
--   (Smart + safe: it brace-counts so it won't break nested tables, and it
--    aborts cleanly if anything looks unusual.)
-- ═══════════════════════════════════════════════════════════

local SSS = game:GetService("ServerScriptService")
local RS  = game:GetService("ReplicatedStorage")

-- find the GameServer script
local gs
for _, n in ipairs({ "GameServer", "RNGManager", "MainServer" }) do
	local s = SSS:FindFirstChild(n)
	if s and s:IsA("Script") and s.Source and s.Source ~= "" then gs = s break end
end
if not gs then
	warn("❌ No GameServer Script found in ServerScriptService. Nothing changed.")
	return
end
print("🔍 Inspecting: " .. gs:GetFullName())

-- make sure ShopData exists
if not RS:FindFirstChild("ShopData") then
	warn("❌ ShopData module missing! Run ECON_01 first.")
	return
end

local src = gs.Source

-- already synced? skip.
if src:find('SHOP_ITEMS%s*=%s*require') then
	print("✅ GameServer already reads SHOP_ITEMS from a require(). Nothing to do!")
	return
end

-- find the SHOP_ITEMS = {  assignment
local sMatch, eMatch = src:find("SHOP_ITEMS%s*=%s*%{")
if not sMatch then
	print("ℹ️  No 'SHOP_ITEMS = {' table found in GameServer.")
	print("   Your shop may use a different name. If so, just set it to:")
	print('       local SHOP_ITEMS = require(ReplicatedStorage:WaitForChild("ShopData")).Items')
	return
end
-- eMatch points at the opening "{"

-- brace-count from the opening { to find the matching }
local function matchBrace(text, openPos)
	local depth = 0
	local inStr = false
	local strCh
	local i = openPos
	while i <= #text do
		local c = text:sub(i, i)
		if inStr then
			if c == strCh then inStr = false end
		elseif c == '"' or c == "'" then
			inStr = true; strCh = c
		elseif c == "{" then
			depth = depth + 1
		elseif c == "}" then
			depth = depth - 1
			if depth == 0 then return i end
		end
		i = i + 1
	end
	return nil
end

local closePos = matchBrace(src, eMatch)
if not closePos then
	warn("❌ Couldn't find the matching '}' for SHOP_ITEMS. Aborting (nothing changed).")
	return
end

-- build the new source: keep everything before "SHOP_ITEMS", swap the table
local replacement = 'SHOP_ITEMS = require(ReplicatedStorage:WaitForChild("ShopData")).Items'
local newSrc = src:sub(1, sMatch - 1) .. replacement .. src:sub(closePos + 1)

-- sanity: count should be sane
gs.Source = newSrc

-- show a little context so you can verify
local ctxStart = math.max(1, sMatch - 15)
local ctxEnd = math.min(#newSrc, sMatch + #replacement + 15)
print("✅ SHOP_ITEMS replaced! New line context:")
print("   ..." .. newSrc:sub(ctxStart, ctxEnd):gsub("\n", " ") .. "...")
print("")
print("🎯 Done! The server now charges whatever price is in ShopData.")
print("   Change a Price in ShopData → dialogue + shop + server all match. 🪄")
print("   💡 Press Play, buy a potion from the NPC to confirm it works.")
