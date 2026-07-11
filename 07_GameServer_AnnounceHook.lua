-- ═══════════════════════════════════════════════════════════
-- 🔧  SYS2 #7 — GAME SERVER ANNOUNCE HOOK  (surgical patch)
-- Paste in:  View ▸ Command Bar   →   Enter
-- Edits:  ServerScriptService ▸ GameServer  (Source)
-- ═══════════════════════════════════════════════════════════
-- 📝 WHAT THIS DOES (one clean edit):
--   1. Adds: local AnnouncementService = require(...) near the top.
--   2. Finds the existing  AnnounceEvent:FireAllClients({...})  line
--      inside your roll handler and REPLACES it with:
--          AnnouncementService:AnnounceDrop(player, name, rarity, tier, mutated)
--      It pulls the ACTUAL variable names out of your original line, so it
--      works even if your variable names differ slightly. ✨
--
--   After this: rare drops go to the global feed (all rares) and the
--   on-screen cutscene only fires for ultra-rare (handled by the service).
-- ═══════════════════════════════════════════════════════════

local SSS = game:GetService("ServerScriptService")
local gs
for _, n in ipairs({ "GameServer", "RNGManager", "MainServer" }) do
	local s = SSS:FindFirstChild(n)
	if s and s:IsA("Script") and s.Source and s.Source ~= "" then gs = s break end
end
if not gs then
	warn("❌ No GameServer Script found in ServerScriptService. Nothing changed.")
	return
end
print("🔧 Patching: " .. gs:GetFullName())

local src = gs.Source

-- ── STEP 1: ensure the AnnouncementService require line exists ──
if not src:find("AnnouncementService") then
	-- insert it right before the roll handler (a very stable anchor)
	local anchor = src:find("RollFunction%.OnServerInvoke")
	if not anchor then anchor = src:find("function%s+RollFunction") end
	if anchor then
		local inj = 'local AnnouncementService = require(game:GetService("ServerScriptService"):WaitForChild("AnnouncementService"))\n'
		src = src:sub(1, anchor - 1) .. inj .. src:sub(anchor)
		print("➕ Injected AnnouncementService require line.")
	else
		-- last-resort: append at the very top after the first 'local'
		local firstLocal = src:find("\nlocal ")
		if firstLocal then
			local inj = '\nlocal AnnouncementService = require(game:GetService("ServerScriptService"):WaitForChild("AnnouncementService"))'
			src = src:sub(1, firstLocal) .. inj .. src:sub(firstLocal + 1)
			print("➕ Injected AnnouncementService require line (top fallback).")
		end
	end
end

-- ── STEP 2: find & replace the AnnounceEvent:FireAllClients(...) call ──
-- Match the whole statement up to the closing ")". We brace/paren count.
local startIdx = src:find("AnnounceEvent%s*:%s*FireAllClients%s*%(")
if not startIdx then
	warn("⚠️ Couldn't find 'AnnounceEvent:FireAllClients(' in GameServer.")
	warn("   The roll handler may already be hooked, or uses a different pattern.")
	print("ℹ️  Manual option: replace that line with:")
	print('       AnnouncementService:AnnounceDrop(player, displayName, aura.Rarity, aura.Tier, mutated)')
	gs.Source = src   -- still save the require injection
	return
end

-- find the matching closing paren for the call (handles nested tables {})
local function matchParen(text, openIdx)
	local depth = 0; local i = openIdx
	local inStr = false; local strCh
	while i <= #text do
		local c = text:sub(i, i)
		if inStr then
			if c == strCh then inStr = false end
		elseif c == '"' or c == "'" then inStr = true; strCh = c
		elseif c == "(" then depth = depth + 1
		elseif c == ")" then
			depth = depth - 1
			if depth == 0 then return i end
		end
		i = i + 1
	end
	return nil
end
-- startIdx points at 'A' of AnnounceEvent; the "(" is somewhere after
local parenOpen = src:find("%(", startIdx)
local parenClose = matchParen(src, parenOpen)
if not parenClose then
	warn("❌ Couldn't find the closing ')' for the AnnounceEvent call. Aborting (require line still saved).")
	gs.Source = src
	return
end

local callText = src:sub(startIdx, parenClose)   -- e.g. AnnounceEvent:FireAllClients({ Player = player.Name, ... })
print("🔍 Found existing line:\n     " .. callText:gsub("%s+", " "))

-- Extract the variable names from the table so we reuse YOUR names
local pName  = callText:match("Player%s*=%s*([%w_]+)%.")  or "player"      -- the player object
local dName  = callText:match("Name%s*=%s*([%w_]+)")      or "displayName" -- the aura name
local rVar   = callText:match("Rarity%s*=%s*([%w_.]+)")   or "aura.Rarity" -- rarity value
local tVar   = callText:match("Tier%s*=%s*([%w_.]+)")     or "aura.Tier"   -- tier label
local mVar   = callText:match("Mutated%s*=%s*([%w_]+)")   or "mutated"     -- mutated flag

local replacement = string.format("AnnouncementService:AnnounceDrop(%s, %s, %s, %s, %s)",
	pName, dName, rVar, tVar, mVar)
print("🔁 Replacing with:\n     " .. replacement)

src = src:sub(1, startIdx - 1) .. replacement .. src:sub(parenClose + 1)

gs.Source = src
print("")
print("✅✅ GAME SERVER HOOKED! Rare drops now route through AnnouncementService.")
print("   → normal rares: global feed only (no popup spam)")
print("   → ultra-rare (>=50000): feed + your existing cutscene/banner")
print("   🎮 Press Play and roll something rare to see the feed light up!")
