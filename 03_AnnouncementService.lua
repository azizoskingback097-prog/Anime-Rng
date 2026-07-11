-- ═══════════════════════════════════════════════════════════
-- 📢  SYS2 #3 — ANNOUNCEMENT SERVICE  (server authority)
-- Paste in:  View ▸ Command Bar   →   Enter
-- Creates:  ServerScriptService ▸ AnnouncementService  (ModuleScript)
-- ═══════════════════════════════════════════════════════════
-- 📝 WHAT THIS DOES:
--   • Called by GameServer whenever a rare aura drops.
--   • Looks up the tier → color + style, RATE-LIMITS spam, then
--     broadcasts a rich message to ALL clients via GlobalAnnounceEvent.
--   • For ULTRA-rare drops it ALSO fires the old AnnounceEvent so your
--     existing cutscene/banner still plays (but normal rares no longer
--     spam big popups — they only go to the feed).
-- ═══════════════════════════════════════════════════════════

local SSS = game:GetService("ServerScriptService")
local old = SSS:FindFirstChild("AnnouncementService"); if old then old:Destroy() end
task.wait(0.1)

local m = Instance.new("ModuleScript")
m.Name = "AnnouncementService"
m.Parent = SSS
m.Source = [====[
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnnouncementService = {}

-- ensure remotes exist
local function ensureRemote(name)
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local r = remotes:FindFirstChild(name)
	if not r then
		r = Instance.new("RemoteEvent"); r.Name = name; r.Parent = remotes
	end
	return r
end
local GlobalAnnounceEvent = ensureRemote("GlobalAnnounceEvent")
local AnnounceEvent       = ensureRemote("AnnounceEvent")

local F = require(ReplicatedStorage:WaitForChild("NumberFormatter"))

--[[
═══════════════════════════════════════════════════════════
📌 CUSTOMIZABLE SECTION: RARITY TIERS  (color + style per tier)
═══════════════════════════════════════════════════════════
  Tiers are matched by the aura's Tier label (from AuraData).
  Style options: "normal" | "rare" | "epic" | "legendary" | "mythic"
  The client uses Style to pick text effects (glow, rainbow, etc.).
────────────────────────────────────────────────────────────
]]
AnnouncementService.Tiers = {
	Common    = { Color = Color3.fromRGB(170,170,170), Style = "normal"    },
	Uncommon  = { Color = Color3.fromRGB(120,255,150), Style = "normal"    },
	Rare      = { Color = Color3.fromRGB(80,160,255),  Style = "rare"      },
	Epic      = { Color = Color3.fromRGB(190,100,255), Style = "epic"      },
	Legendary = { Color = Color3.fromRGB(255,200,40),  Style = "legendary" },
	Mythic    = { Color = Color3.fromRGB(255,120,220), Style = "mythic"    },
}

-- 📌 Drop is announced only if rarity >= this (1 in N).
AnnouncementService.RARE_THRESHOLD   = 1000
-- 📌 Drops at/above this ALSO trigger the on-screen banner/cutscene.
AnnouncementService.ULTRA_THRESHOLD  = 50000

-- 📌 RATE LIMITING (prevents feed spam during luck spikes)
AnnouncementService.PER_PLAYER_COOLDOWN = 1.5   -- seconds between one player's drops
AnnouncementService.GLOBAL_MAX_PER_10S   = 8    -- max messages across everyone in 10s

-- ── state ────────────────────────────────────────────────
local lastPlayerAnnounce = {}     -- [player] = clock
local globalTimes = {}            -- rolling timestamps of recent broadcasts

local function globalSlotsFree()
	local now = os.clock()
	-- purge older than 10s
	for i = #globalTimes, 1, -1 do
		if now - globalTimes[i] > 10 then table.remove(globalTimes, i) end
	end
	return #globalTimes < AnnouncementService.GLOBAL_MAX_PER_10S
end

local function tierFor(tierLabel, rarity)
	local t = AnnouncementService.Tiers[tierLabel]
	if not t then
		-- fall back by magnitude
		if rarity >= 50000 then t = AnnouncementService.Tiers.Mythic
		elseif rarity >= 5000 then t = AnnouncementService.Tiers.Legendary
		elseif rarity >= 1000 then t = AnnouncementService.Tiers.Rare
		else t = AnnouncementService.Tiers.Common end
	end
	return t
end

--[[
  AnnounceDrop(player, name, rarity, tierLabel, mutated)
    Called by GameServer when a rare aura is rolled.
]]
function AnnouncementService.AnnounceDrop(player, name, rarity, tierLabel, mutated)
	rarity = tonumber(rarity) or 0
	if rarity < AnnouncementService.RARE_THRESHOLD then return end

	-- per-player cooldown
	local now = os.clock()
	if lastPlayerAnnounce[player] and (now - lastPlayerAnnounce[player]) < AnnouncementService.PER_PLAYER_COOLDOWN then
		return
	end

	-- global rate limit
	if not globalSlotsFree() then return end
	table.insert(globalTimes, now)
	lastPlayerAnnounce[player] = now

	local tier = tierFor(tierLabel, rarity)
	local oddsText = F.FormatOddsNumber(rarity)

	-- 🔔 broadcast to the global chat feed (all clients)
	GlobalAnnounceEvent:FireAllClients({
		Player  = player.Name,
		Name    = name,
		Odds    = oddsText,
		Rarity  = rarity,
		Tier    = tierLabel,
		Color   = tier.Color,
		Style   = tier.Style,
		Mutated = mutated == true,
	})

	-- 🎬 for ULTRA-rare, also fire the legacy event so the cutscene/banner still plays
	if rarity >= AnnouncementService.ULTRA_THRESHOLD then
		AnnounceEvent:FireAllClients({
			Player = player.Name, Name = name, Rarity = rarity, Tier = tierLabel, Mutated = mutated == true,
		})
	end
end

-- ═══════════════════════════════════════════════════════════
-- 📣 ADMIN BROADCAST  (simple API: AnnouncementService.AdminBroadcast(adminPlayer, text))
-- ═══════════════════════════════════════════════════════════

-- 📌 ADMIN LIST (UserIds OR usernames who may broadcast). SERVER-AUTHORITATIVE.
AnnouncementService.ADMIN_IDS       = { 12345678 }
AnnouncementService.ADMIN_USERNAMES = { "Twix79i" }

function AnnouncementService.IsAdmin(player)
	if not player then return false end
	if table.find(AnnouncementService.ADMIN_IDS, player.UserId) then return true end
	if table.find(AnnouncementService.ADMIN_USERNAMES, player.Name) then return true end
	return false
end

-- server-validated broadcast to all clients (avatar + checkmark panel)
function AnnouncementService.AdminBroadcast(adminPlayer, text)
	if not AnnouncementService.IsAdmin(adminPlayer) then
		warn("⛔ Non-admin tried to broadcast: " .. tostring(adminPlayer and adminPlayer.Name))
		return false
	end
	text = tostring(text or ""):sub(1, 200)   -- clamp length
	local remote = ensureRemote("AdminBroadcastEvent")
	remote:FireAllClients({
		AdminName = adminPlayer.Name,
		AdminId   = adminPlayer.UserId,
		Message   = text,
	})
	return true
end

return AnnouncementService
]====]

print("✅ AnnouncementService (server) created.")
print("   Drop announce + rate limiting + admin broadcast ready.")
print("   ⚠️ Remember to run SYS2 #7 (GameServer hook) so drops reach it!")
