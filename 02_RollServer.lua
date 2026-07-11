-- ═══════════════════════════════════════════════════════════
-- 🧠  ROLL SERVER  —  Script   |   PLACE IN: ServerScriptService
-- ═══════════════════════════════════════════════════════════
-- 📝 WHAT IT DOES (simple words):
-- The brain. Handles FIVE things now:
--   1. ROLLING      → client asks, server rolls, returns result
--   2. INVENTORY    → client asks "what do I own?" → returns a list
--   3. EQUIP        → client asks "wear this aura" → sets it
--   4. ADMIN        → admins give auras / set luck / clear inventory
--   5. STATS        → tracks total rolls, rarest pull, auras found
--
-- 🎨 HOW TO CUSTOMIZE:
--   • Make yourself admin → add your username to ADMIN_USERNAMES or UserId to ADMIN_IDS
--   • Roll speed          → ROLL_COOLDOWN
--   • Base luck           → LUCK
--   • What's "rare"       → ANNOUNCE_RARITY
--
-- 🔗 RELATED SCRIPTS:
--   • AuraDatabase → roll algorithm + aura data
--   • RollUI       → calls RollFunction
--   • InventoryUI  → calls GetInventoryFunction + EquipFunction
--   • AdminPanel   → calls AdminFunction
--   • StatsUI      → calls GetStatsFunction, listens to StatsUpdatedEvent
--
-- 💡 SUGGESTION / EXAMPLE ADDITION:
--   Track "Rolls Since Rare" (how many rolls since your last rare pull)
--   as a pity-ish counter shown in stats.
-- ═══════════════════════════════════════════════════════════

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local AuraData = require(ReplicatedStorage:WaitForChild("AuraDatabase"))

-- ⚙️ ─────────────────── CUSTOMIZE: SETTINGS ───────────────────
local ADMIN_IDS        = { 12345678, 87654321 }   -- by Roblox UserId
local ADMIN_USERNAMES  = { "Twix79i" }            -- ⚙️ BY USERNAME (your main admin!)
local ROLL_COOLDOWN    = 0.5
local LUCK             = 1
local ANNOUNCE_RARITY  = 1000
local AUTO_EQUIP_FIRST = true
-- ⚙️ ───────────────────────── END CUSTOMIZE ───────────────────

local Remotes              = ReplicatedStorage:WaitForChild("Remotes")
local RollFunction         = Remotes:WaitForChild("RollFunction")
local AnnounceEvent        = Remotes:WaitForChild("AnnounceEvent")
local GetInventoryFunction = Remotes:WaitForChild("GetInventoryFunction")
local EquipFunction        = Remotes:WaitForChild("EquipFunction")
local AdminFunction        = Remotes:WaitForChild("AdminFunction")
local GetStatsFunction     = Remotes:WaitForChild("GetStatsFunction")
local StatsUpdatedEvent    = Remotes:WaitForChild("StatsUpdatedEvent")

local PlayerData = {}
local lastRoll   = {}

local function isAdmin(player)
	for _, id in ipairs(ADMIN_IDS) do
		if player.UserId == id then return true end
	end
	for _, name in ipairs(ADMIN_USERNAMES) do
		if player.Name == name then return true end
	end
	return false
end

local function getData(player)
	if not PlayerData[player] then
		PlayerData[player] = {
			Inventory = {},
			Equipped  = nil,
			Rolls     = 0,
			Luck      = LUCK,
			RarestAura   = "None",
			RarestRarity = 0,
		}
	end
	PlayerData[player].Luck = PlayerData[player].Luck or LUCK
	return PlayerData[player]
end

-- build a stats snapshot from player data (used by GetStats + StatsUpdatedEvent)
local function buildStats(data)
	local unique = {}
	for _, name in ipairs(data.Inventory) do
		unique[name] = true
	end
	local found = 0
	for _ in pairs(unique) do found = found + 1 end
	return {
		Rolls        = data.Rolls,
		RarestAura   = data.RarestAura,
		RarestRarity = data.RarestRarity,
		Luck         = data.Luck,
		Found        = found,
		Total        = #AuraData.Auras,
	}
end

-- ────────────── 1) ROLLING ──────────────
RollFunction.OnServerInvoke = function(player)
	local now = os.clock()
	if lastRoll[player] and (now - lastRoll[player]) < ROLL_COOLDOWN then
		return nil
	end
	lastRoll[player] = now

	local data = getData(player)
	data.Rolls = data.Rolls + 1

	local aura = AuraData.GetWeightedRandom(data.Luck)
	table.insert(data.Inventory, aura.Name)

	-- 📊 track rarest pull
	if aura.Rarity > data.RarestRarity then
		data.RarestRarity = aura.Rarity
		data.RarestAura   = aura.Name
	end

	if AUTO_EQUIP_FIRST and data.Equipped == nil then
		data.Equipped = aura.Name
	end

	if aura.Rarity >= ANNOUNCE_RARITY then
		AnnounceEvent:FireAllClients({
			Player = player.Name,
			Name   = aura.Name,
			Rarity = aura.Rarity,
			Tier   = aura.Tier,
		})
	end

	-- 📊 push updated stats to the player's StatsUI
	StatsUpdatedEvent:FireClient(player, buildStats(data))

	return {
		Name       = aura.Name,
		Rarity     = aura.Rarity,
		Tier       = aura.Tier,
		TotalRolls = data.Rolls,
		Color      = aura.Color,
	}
end

-- ────────────── 2) INVENTORY ──────────────
GetInventoryFunction.OnServerInvoke = function(player)
	local data = getData(player)
	local counts = {}
	for _, name in ipairs(data.Inventory) do
		counts[name] = (counts[name] or 0) + 1
	end
	return { Counts = counts, Equipped = data.Equipped }
end

-- ────────────── 3) EQUIP ──────────────
EquipFunction.OnServerInvoke = function(player, auraName)
	local data = getData(player)
	for _, name in ipairs(data.Inventory) do
		if name == auraName then data.Equipped = auraName; return true end
	end
	return false
end

-- ────────────── 4) ADMIN ──────────────
AdminFunction.OnServerInvoke = function(player, action, value)
	if not isAdmin(player) then return nil end
	local data = getData(player)

	if action == "IsAdmin" then
		return true

	elseif action == "GiveAura" then
		local aura = AuraData.GetByName(value)
		if not aura then return false end
		table.insert(data.Inventory, aura.Name)
		StatsUpdatedEvent:FireClient(player, buildStats(data))  -- refresh stats (found count)
		return true

	elseif action == "SetLuck" then
		data.Luck = math.max(1, math.floor(tonumber(value) or 1))
		StatsUpdatedEvent:FireClient(player, buildStats(data))  -- refresh stats (luck shown)
		return data.Luck

	elseif action == "GiveRare" then
		local aura = AuraData.GetWeightedRandom(5000)
		table.insert(data.Inventory, aura.Name)
		StatsUpdatedEvent:FireClient(player, buildStats(data))
		return aura.Name

	elseif action == "ClearInventory" then
		data.Inventory = {}
		data.Equipped = nil
		StatsUpdatedEvent:FireClient(player, buildStats(data))
		return true
	end

	return nil
end

-- ────────────── 5) STATS ──────────────
GetStatsFunction.OnServerInvoke = function(player)
	return buildStats(getData(player))
end

-- send fresh stats when a player joins (so the panel isn't empty)
Players.PlayerAdded:Connect(function(player)
	task.wait(1)  -- give the client a moment to load
	if PlayerData[player] then
		StatsUpdatedEvent:FireClient(player, buildStats(PlayerData[player]))
	end
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerData[player] = nil
	lastRoll[player]   = nil
end)

print("✅ RollServer running! (Rolling + Inventory + Equip + Admin + Stats)")
