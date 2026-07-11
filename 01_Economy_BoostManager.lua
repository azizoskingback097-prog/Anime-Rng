-- ═══════════════════════════════════════════════════════════
-- 💰 ECONOMY REBALANCE + BOOST MANAGER SETUP
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- Updates:
--   • New coin formula (15-20 min to afford first potion)
--   • BoostManager ModuleScript (offline pause, stacking)
--   • New Remotes for Shop & Boosts
-- ═══════════════════════════════════════════════════════════

local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")

-- 1. Create new Remotes
local remotes = RS:FindFirstChild("Remotes")
if not remotes:FindFirstChild("PurchaseItemFunction") then
	local f = Instance.new("RemoteFunction"); f.Name = "PurchaseItemFunction"; f.Parent = remotes
end
if not remotes:FindFirstChild("ShopOpenEvent") then
	local e = Instance.new("RemoteEvent"); e.Name = "ShopOpenEvent"; e.Parent = remotes
end
if not remotes:FindFirstChild("BoostUpdateEvent") then
	local e = Instance.new("RemoteEvent"); e.Name = "BoostUpdateEvent"; e.Parent = remotes
end

-- 2. Create BoostManager ModuleScript
local oldBM = SSS:FindFirstChild("BoostManager")
if oldBM then oldBM:Destroy() end
task.wait(0.1)

local bm = Instance.new("ModuleScript")
bm.Name = "BoostManager"
bm.Parent = SSS
bm.Source = [==[
-- ═══════════════════════════════════════════════════════════
-- 🧪 BOOST MANAGER (Server-Authoritative + Offline Pause)
-- ═══════════════════════════════════════════════════════════
local BoostManager = {}

-- ⚙️ BOOST DEFINITIONS (Add more items here!)
BoostManager.Items = {
	["LuckPotion"] = {
		Price = 100000,
		Duration = 300, -- 5 minutes in seconds
		Type = "LuckMultiplier",
		Value = 2.0,
		DisplayName = "x2 Luck Potion"
	},
	["CoinBoost"] = {
		Price = 200000,
		Duration = 300, -- 5 minutes
		Type = "CoinMultiplier",
		Value = 2.0,
		DisplayName = "x2 Coins Boost"
	}
}

-- Active boosts: [player] = { LuckMultiplier = { expiresAt = 1234567.89 } }
local activeBoosts = {}
local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
local BoostUpdateEvent = Remotes:WaitForChild("BoostUpdateEvent")

-- Initialize player data
function BoostManager.InitPlayer(player)
	if not activeBoosts[player] then
		activeBoosts[player] = {}
	end
end

-- Load boosts from saved data (called on join)
function BoostManager.LoadBoosts(player, savedBoosts)
	BoostManager.InitPlayer(player)
	if not savedBoosts then return end
	
	for boostType, data in pairs(savedBoosts) do
		-- data.RemainingSeconds was saved when they left
		if data.RemainingSeconds and data.RemainingSeconds > 0 then
			activeBoosts[player][boostType] = {
				expiresAt = os.clock() + data.RemainingSeconds
			}
		end
	end
	BoostManager.NotifyClient(player)
end

-- Save boosts for offline (called on leave)
function BoostManager.SaveBoosts(player)
	local data = activeBoosts[player]
	if not data then return nil end
	
	local toSave = {}
	for boostType, boostData in pairs(data) do
		local remaining = boostData.expiresAt - os.clock()
		if remaining > 0 then
			toSave[boostType] = { RemainingSeconds = remaining }
		end
	end
	return toSave
end

-- Purchase an item
function BoostManager.Purchase(player, itemId)
	local item = BoostManager.Items[itemId]
	if not item then return false, "Item not found!" end
	
	BoostManager.InitPlayer(player)
	
	-- Get GameServer to check coins
	local GameServer = require(script.Parent:WaitForChild("GameServer"))
	local playerData = GameServer.GetPlayerData(player)
	if not playerData then return false, "Data not loaded!" end
	
	-- Check coins
	if playerData.Coins < item.Price then
		return false, "Not enough coins! Need " .. item.Price .. ", have " .. playerData.Coins
	end
	
	-- Deduct coins
	playerData.Coins = playerData.Coins - item.Price
	
	-- Apply boost (STACK TIME if already active!)
	local boostType = item.Type
	if not activeBoosts[player][boostType] then
		-- New boost
		activeBoosts[player][boostType] = {
			expiresAt = os.clock() + item.Duration
		}
	else
		-- Stack: Add time to existing
		local remaining = activeBoosts[player][boostType].expiresAt - os.clock()
		if remaining < 0 then remaining = 0 end
		activeBoosts[player][boostType].expiresAt = os.clock() + remaining + item.Duration
	end
	
	-- Notify GameServer to save & update stats
	GameServer.UpdateStats(player)
	
	-- Notify client
	BoostManager.NotifyClient(player)
	
	print("🧪 " .. player.Name .. " purchased " .. itemId .. " for " .. item.Price .. " coins!")
	return true, "Purchased " .. item.DisplayName .. "!"
end

-- Get coin multiplier
function BoostManager.GetCoinMultiplier(player)
	if not activeBoosts[player] then return 1.0 end
	local boost = activeBoosts[player]["CoinMultiplier"]
	if not boost then return 1.0 end
	if os.clock() >= boost.expiresAt then return 1.0 end
	return BoostManager.Items["CoinBoost"].Value
end

-- Get luck multiplier
function BoostManager.GetLuckMultiplier(player)
	if not activeBoosts[player] then return 1.0 end
	local boost = activeBoosts[player]["LuckMultiplier"]
	if not boost then return 1.0 end
	if os.clock() >= boost.expiresAt then return 1.0 end
	return BoostManager.Items["LuckPotion"].Value
end

-- Send boost data to client for UI
function BoostManager.NotifyClient(player)
	local data = activeBoosts[player]
	if not data then return end
	
	local clientData = {}
	for boostType, boostData in pairs(data) do
		local remaining = boostData.expiresAt - os.clock()
		if remaining > 0 then
			clientData[boostType] = {
				Remaining = remaining,
				Value = (boostType == "LuckMultiplier") and BoostManager.Items["LuckPotion"].Value or BoostManager.Items["CoinBoost"].Value
			}
		end
	end
	BoostUpdateEvent:FireClient(player, clientData)
end

-- Cleanup expired boosts periodically
task.spawn(function()
	while true do
		task.wait(10)
		for player, boosts in pairs(activeBoosts) do
			local changed = false
			for boostType, data in pairs(boosts) do
				if os.clock() >= data.expiresAt then
					boosts[boostType] = nil
					changed = true
					print("⏰ " .. player.Name .. "'s " .. boostType .. " expired!")
				end
			end
			if changed then BoostManager.NotifyClient(player) end
		end
	end
end)

function BoostManager.Cleanup(player)
	activeBoosts[player] = nil
end

return BoostManager
]==]

-- 3. Update GameServer with new coin formula + boost integration
local oldGS = SSS:FindFirstChild("GameServer")
if oldGS then oldGS:Destroy() end
task.wait(0.1)

local gs = Instance.new("Script")
gs.Name = "GameServer"
gs.Parent = SSS
gs.Source = [==[
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local AuraData = require(ReplicatedStorage:WaitForChild("AuraData"))

local ADMIN_IDS = { 12345678, 87654321 }
local ADMIN_USERNAMES = { "Twix79i" }
local ROLL_COOLDOWN = 0.5
local LUCK = 1
local ANNOUNCE_RARITY = 1000
local AUTO_EQUIP_FIRST = true
local AUTOSAVE_INTERVAL = 60
local DATASTORE_KEY = "AnimeRNG_v2_Coins"

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RollFunction = Remotes:WaitForChild("RollFunction")
local AnnounceEvent = Remotes:WaitForChild("AnnounceEvent")
local ChatAnnounceEvent = Remotes:WaitForChild("ChatAnnounceEvent")
local GetInventoryFunction = Remotes:WaitForChild("GetInventoryFunction")
local EquipFunction = Remotes:WaitForChild("EquipFunction")
local AdminFunction = Remotes:WaitForChild("AdminFunction")
local GetStatsFunction = Remotes:WaitForChild("GetStatsFunction")
local StatsUpdatedEvent = Remotes:WaitForChild("StatsUpdatedEvent")
local AdminStatusEvent = Remotes:WaitForChild("AdminStatusEvent")
local WeatherChangedEvent = Remotes:WaitForChild("WeatherChangedEvent")
local EquippedChangedEvent = Remotes:WaitForChild("EquippedChangedEvent")
local CoinRewardEvent = Remotes:WaitForChild("CoinRewardEvent")
local PurchaseItemFunction = Remotes:WaitForChild("PurchaseItemFunction")
local ShopOpenEvent = Remotes:WaitForChild("ShopOpenEvent")
local currentWeatherValue = ReplicatedStorage:WaitForChild("CurrentWeather")

local playerStore
pcall(function() playerStore = DataStoreService:GetDataStore(DATASTORE_KEY) end)
local PlayerData = {}
local lastRoll = {}

local function isAdmin(player)
	for _, id in ipairs(ADMIN_IDS) do if player.UserId == id then return true end end
	local pn = string.lower(player.Name); local dn = string.lower(player.DisplayName)
	for _, name in ipairs(ADMIN_USERNAMES) do
		if pn == string.lower(name) or dn == string.lower(name) then return true end
	end
	return false
end

local function newData()
	return { Inventory = {}, Equipped = nil, Rolls = 0, Luck = LUCK, RarestAura = "None", RarestRarity = 0, Coins = 0 }
end

local function ensureFields(d)
	d.Inventory = d.Inventory or {}; d.Equipped = d.Equipped or nil; d.Rolls = d.Rolls or 0
	d.Luck = d.Luck or LUCK; d.RarestAura = d.RarestAura or "None"; d.RarestRarity = d.RarestRarity or 0
	d.Coins = d.Coins or 0; d.Boosts = d.Boosts or nil
	return d
end

local function getData(p)
	if not PlayerData[p] then PlayerData[p] = newData() end
	return PlayerData[p]
end

-- ⭐ EXPOSED FOR BoostManager
function GetPlayerData(player) return getData(player) end
function UpdateStats(player)
	if PlayerData[player] then StatsUpdatedEvent:FireClient(player, buildStats(PlayerData[player])) end
end

local function buildStats(d)
	local unique = {}
	for _, name in ipairs(d.Inventory) do unique[name] = true end
	local found = 0
	for _ in pairs(unique) do found = found + 1 end
	return { Rolls = d.Rolls, RarestAura = d.RarestAura, RarestRarity = d.RarestRarity, Luck = d.Luck, Found = found, Total = #AuraData.Auras, Coins = d.Coins }
end

local function loadData(p)
	if playerStore then
		local k = "Player_" .. p.UserId
		local s, r = pcall(function() return playerStore:GetAsync(k) end)
		if s and r then PlayerData[p] = ensureFields(r) else PlayerData[p] = newData() end
	else PlayerData[p] = newData() end
	task.wait(0.5)
	if PlayerData[p] then
		StatsUpdatedEvent:FireClient(p, buildStats(PlayerData[p]))
		if PlayerData[p].Equipped then EquippedChangedEvent:FireClient(p, PlayerData[p].Equipped) end
		-- Load boosts
		local BoostManager = require(script.Parent:WaitForChild("BoostManager"))
		BoostManager.LoadBoosts(p, PlayerData[p].Boosts)
	end
end

local function saveData(p)
	local d = PlayerData[p]; if not d or not playerStore then return end
	-- Save boosts (pause offline)
	local BoostManager = require(script.Parent:WaitForChild("BoostManager"))
	d.Boosts = BoostManager.SaveBoosts(p)
	pcall(function() playerStore:SetAsync("Player_" .. p.UserId, d) end)
end

-- 💰 NEW COIN FORMULA (15-20 min target for first potion)
local function calculateCoins(rarity)
	-- Base: Flat reward + scaling
	-- Rarity 1 = 55 coins, Rarity 16 = 130, Rarity 1000 = 5050
	return math.floor(rarity * 5) + 50
end

local MUTATION_MULTIPLIERS = { Sandy = 1.25, Cosmic = 1.5, Cursed = 1.75 }

RollFunction.OnServerInvoke = function(player)
	local now = os.clock()
	if lastRoll[player] and (now - lastRoll[player]) < ROLL_COOLDOWN then return nil end
	lastRoll[player] = now
	
	local data = getData(player)
	data.Rolls = data.Rolls + 1
	
	-- ⭐ CHECK LUCK BOOST
	local BoostManager = require(script.Parent:WaitForChild("BoostManager"))
	local luckMultiplier = BoostManager.GetLuckMultiplier(player)
	local effectiveLuck = data.Luck * luckMultiplier
	
	local aura = AuraData.GetWeightedRandom(effectiveLuck)
	
	local storedName = aura.Name
	local displayName = aura.Name
	local displayColor = aura.Color
	local mutated = false
	local mutationName = nil
	
	local wn = currentWeatherValue.Value
	if wn and wn ~= "Clear" then
		local WeatherData = require(ReplicatedStorage:WaitForChild("WeatherData"))
		local weather = WeatherData.GetByName(wn)
		if weather and weather.Mutation and weather.Mutation.Chance > 0 then
			if math.random() <= weather.Mutation.Chance then
				storedName = weather.Mutation.Name .. "|" .. aura.Name
				displayName = weather.Mutation.Name .. " " .. aura.Name
				displayColor = weather.Mutation.Color or aura.Color
				mutated = true
				mutationName = weather.Mutation.Name
			end
		end
	end
	
	table.insert(data.Inventory, storedName)
	if aura.Rarity > data.RarestRarity then data.RarestRarity = aura.Rarity; data.RarestAura = displayName end
	if AUTO_EQUIP_FIRST and data.Equipped == nil then data.Equipped = storedName; EquippedChangedEvent:FireClient(player, storedName) end
	
	-- 💰 COIN REWARD WITH BOOST
	local baseCoins = calculateCoins(aura.Rarity)
	if mutated and mutationName and MUTATION_MULTIPLIERS[mutationName] then
		baseCoins = math.floor(baseCoins * MUTATION_MULTIPLIERS[mutationName])
	end
	-- ⭐ APPLY COIN BOOST
	local coinMultiplier = BoostManager.GetCoinMultiplier(player)
	local finalCoins = math.floor(baseCoins * coinMultiplier)
	data.Coins = data.Coins + finalCoins
	
	CoinRewardEvent:FireClient(player, { Amount = finalCoins, Mutated = mutated })

	if aura.Rarity >= ANNOUNCE_RARITY then
		local ad = { Player = player.Name, Name = displayName, Rarity = aura.Rarity, Tier = aura.Tier, Color = displayColor, Mutated = mutated }
		AnnounceEvent:FireAllClients(ad)
		ChatAnnounceEvent:FireAllClients(ad)
	end
	
	StatsUpdatedEvent:FireClient(player, buildStats(data))
	return { Name = storedName, DisplayName = displayName, Rarity = aura.Rarity, Tier = aura.Tier, TotalRolls = data.Rolls, Color = displayColor, Mutated = mutated }
end

-- 🛒 SHOP PURCHASE HANDLER
PurchaseItemFunction.OnServerInvoke = function(player, itemId)
	local BoostManager = require(script.Parent:WaitForChild("BoostManager"))
	return BoostManager.Purchase(player, itemId)
end

GetInventoryFunction.OnServerInvoke = function(player)
	local data = getData(player); local counts = {}
	for _, name in ipairs(data.Inventory) do counts[name] = (counts[name] or 0) + 1 end
	return { Counts = counts, Equipped = data.Equipped }
end

EquipFunction.OnServerInvoke = function(player, auraName)
	local data = getData(player)
	for _, name in ipairs(data.Inventory) do
		if name == auraName then data.Equipped = auraName; EquippedChangedEvent:FireClient(player, auraName); return true end
	end
	return false
end

AdminFunction.OnServerInvoke = function(player, action, value)
	if not isAdmin(player) then return nil end
	local data = getData(player)
	if action == "IsAdmin" then return true
	elseif action == "GiveAura" then
		local aura = AuraData.GetByName(value)
		if not aura then return false end
		table.insert(data.Inventory, aura.Name); StatsUpdatedEvent:FireClient(player, buildStats(data)); return true
	elseif action == "ForceWeather" then
		local WeatherData = require(ReplicatedStorage:WaitForChild("WeatherData"))
		local weather = WeatherData.GetByName(value)
		if not weather then return false end
		currentWeatherValue.Value = weather.Name
		WeatherChangedEvent:FireAllClients({ Name = weather.Name, Lighting = weather.Lighting, Particles = weather.Particles, Skybox = weather.Skybox, BannerText = weather.BannerText, BannerColor = weather.BannerColor })
		return true
	elseif action == "SetLuck" then
		data.Luck = math.max(1, math.floor(tonumber(value) or 1)); StatsUpdatedEvent:FireClient(player, buildStats(data)); return data.Luck
	elseif action == "GiveRare" then
		local aura = AuraData.GetWeightedRandom(5000)
		table.insert(data.Inventory, aura.Name); StatsUpdatedEvent:FireClient(player, buildStats(data)); return aura.Name
	elseif action == "ClearInventory" then
		data.Inventory = {}; data.Equipped = nil; EquippedChangedEvent:FireClient(player, nil); StatsUpdatedEvent:FireClient(player, buildStats(data)); return true
	elseif action == "ResetData" then
		PlayerData[player] = newData(); EquippedChangedEvent:FireClient(player, nil); StatsUpdatedEvent:FireClient(player, buildStats(PlayerData[player])); return true
	end
	return nil
end

GetStatsFunction.OnServerInvoke = function(player) return buildStats(getData(player)) end

Players.PlayerAdded:Connect(function(player)
	loadData(player); task.wait(1.5)
	if isAdmin(player) then AdminStatusEvent:FireClient(player, true) end
end)
Players.PlayerRemoving:Connect(function(player) saveData(player); PlayerData[player] = nil; lastRoll[player] = nil end)
task.spawn(function() while true do task.wait(AUTOSAVE_INTERVAL) for p in pairs(PlayerData) do saveData(p) end end end)
game:BindToClose(function() for p in pairs(PlayerData) do saveData(p) end task.wait(2) end)
print("GameServer running! (V3 - Economy Rebalanced + Boosts Integrated)")
]==]

print("✅ ECONOMY + BOOST MANAGER DEPLOYED!")
print("💰 New coin formula: Rarity × 5 + 50 (15-20 min target)")
print("🧪 BoostManager created with offline pause logic!")
