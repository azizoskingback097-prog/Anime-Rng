-- ═══════════════════════════════════════════════════════════
-- 🧠  RNG MANAGER  —  Script   |   PLACE IN: ServerScriptService
-- ═══════════════════════════════════════════════════════════
-- 📝 WHAT IT DOES (simple words):
-- The brain of the game. When a player clicks ROLL, the client
-- asks this server script. The server runs the RNG (so players
-- can't cheat), stores the aura in that player's inventory,
-- announces it to everyone if it's rare, and sends the result
-- back to the player who rolled.
--
-- 🎨 HOW TO CUSTOMIZE:
--   • Roll speed      → change ROLL_COOLDOWN (seconds between rolls)
--   • Lucky boosts    → change LUCK (higher = rarer pulls, it rolls N times & keeps best)
--   • What's "rare"   → change ANNOUNCE_RARITY (anything 1-in-that-or-rarer gets announced)
--   • First aura auto-worn → toggle AUTO_EQUIP_FIRST
--
-- 🔗 RELATED SCRIPTS:
--   • AuraData        → this script calls AuraData.GetWeightedRandom()
--   • RollClient      → calls RollFunction (the RemoteFunction this script answers)
--   • (Phase 2) Inventory will read PlayerData created here
--
-- 💡 SUGGESTION / EXAMPLE ADDITION:
--   Give players a limited number of rolls + a "recharge" timer:
--     add  local MaxRolls = 50  and subtract from data.RollsLeft,
--     then return "no_rolls" instead of an aura when it hits 0.
--   Pair it with a "+1 roll every 3 sec" loop and a client meter.
-- ═══════════════════════════════════════════════════════════

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local AuraData = require(ReplicatedStorage:WaitForChild("AuraData"))

-- ⚙️ ─────────────────── CUSTOMIZE: SETTINGS ───────────────────
local ROLL_COOLDOWN   = 0.5    -- seconds players must wait between rolls (anti-spam)
local LUCK            = 1      -- global luck multiplier (2 = roll twice, keep rarest)
local ANNOUNCE_RARITY = 1000   -- any aura 1-in-this-or-rarer is announced to everyone
local AUTO_EQUIP_FIRST = true  -- automatically "wear" the first aura a new player rolls
-- ⚙️ ───────────────────────── END CUSTOMIZE ───────────────────

-- locate the remotes (created by the command-bar setup script)
local Remotes       = ReplicatedStorage:WaitForChild("Remotes")
local RollFunction  = Remotes:WaitForChild("RollFunction")
local AnnounceEvent = Remotes:WaitForChild("AnnounceEvent")

-- per-player runtime data (wipes when they leave; Phase 5 adds real saving)
local PlayerData = {}   -- [player] = { Inventory = {}, Equipped = nil, Rolls = 0 }
local lastRoll   = {}   -- [player] = tick() of last roll (for cooldown)

local function getData(player)
	if not PlayerData[player] then
		PlayerData[player] = { Inventory = {}, Equipped = nil, Rolls = 0 }
	end
	return PlayerData[player]
end

-- the client asked the server to roll
RollFunction.OnServerInvoke = function(player)
	-- cooldown check
	local now = os.clock()
	if lastRoll[player] and (now - lastRoll[player]) < ROLL_COOLDOWN then
		return nil   -- too fast, tell the client "wait"
	end
	lastRoll[player] = now

	local data  = getData(player)
	data.Rolls += 1

	-- ⚡ THE ACTUAL ROLL (server-authoritative, can't be cheated)
	local aura = AuraData.GetWeightedRandom(LUCK)
	table.insert(data.Inventory, aura.Name)

	if AUTO_EQUIP_FIRST and data.Equipped == nil then
		data.Equipped = aura.Name
	end

	-- 📢 announce rare pulls to everyone
	if aura.Rarity >= ANNOUNCE_RARITY then
		AnnounceEvent:FireAllClients({
			Player = player.Name,
			Name   = aura.Name,
			Rarity = aura.Rarity,
			Tier   = aura.Tier,
		})
	end

	-- send the result back to whoever rolled
	return {
		Name  = aura.Name,
		Rarity = aura.Rarity,
		Tier  = aura.Tier,
		TotalRolls = data.Rolls,
		Color = aura.Color,   -- so the client can color the text without looking it up
	}
end

-- clean up when a player leaves
Players.PlayerRemoving:Connect(function(player)
	PlayerData[player] = nil
	lastRoll[player]   = nil
end)

print("✅ RNGManager running. Rolling is live!")
