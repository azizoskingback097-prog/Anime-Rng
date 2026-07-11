-- ═══════════════════════════════════════════════════════════
-- 💰 SERVER UPDATE: COIN ECONOMY & MUTATION MULTIPLIERS
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- Adds Coins to player data. Every roll grants coins based on rarity.
-- Mutations grant bonus multipliers (Sandy = 1.25x, etc.)
-- ═══════════════════════════════════════════════════════════

local SSS = game:GetService("ServerScriptService")
local RS = game:GetService("ReplicatedStorage")

-- Create the Coin Event if it doesn't exist
local remotes = RS:FindFirstChild("Remotes")
if not remotes:FindFirstChild("CoinRewardEvent") then
	local ev = Instance.new("RemoteEvent")
	ev.Name = "CoinRewardEvent"
	ev.Parent = remotes
end

-- Update GameServer
local old = SSS:FindFirstChild("GameServer")
if old then old:Destroy() end
task.wait(0.1)

local s = Instance.new("Script")
s.Name = "GameServer"
s.Parent = SSS
s.Source = [==[
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
local currentWeatherValue = ReplicatedStorage:WaitForChild("CurrentWeather")

local playerStore
pcall(function() playerStore = DataStoreService:GetDataStore(DATASTORE_KEY) end)
local PlayerData = {}
local lastRoll = {}

-- 💰 MUTATION MULTIPLIERS
local MUTATION_MULTIPLIERS = {
	Sandy = 1.25,
	Cosmic = 1.5,
	Cursed = 1.75,
}

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
	d.Coins = d.Coins or 0
	return d
end

local function getData(p)
	if not PlayerData[p] then PlayerData[p] = newData() end
	return PlayerData[p]
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
	end
end

local function saveData(p)
	local d = PlayerData[p]; if not d or not playerStore then return end
	pcall(function() playerStore:SetAsync("Player_" .. p.UserId, d) end)
end

RollFunction.OnServerInvoke = function(player)
	local now = os.clock()
	if lastRoll[player] and (now - lastRoll[player]) < ROLL_COOLDOWN then return nil end
	lastRoll[player] = now
	
	local data = getData(player)
	data.Rolls = data.Rolls + 1
	local aura = AuraData.GetWeightedRandom(data.Luck)
	
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
	
	-- 💰 COIN REWARD LOGIC
	local baseCoins = math.floor(aura.Rarity / 10) + 5
	local finalCoins = baseCoins
	if mutated and mutationName and MUTATION_MULTIPLIERS[mutationName] then
		finalCoins = math.floor(baseCoins * MUTATION_MULTIPLIERS[mutationName])
	end
	data.Coins = data.Coins + finalCoins
	
	-- Send Coin Reward to Client UI
	CoinRewardEvent:FireClient(player, { Amount = finalCoins, Mutated = mutated })

	if aura.Rarity >= ANNOUNCE_RARITY then
		local ad = { Player = player.Name, Name = displayName, Rarity = aura.Rarity, Tier = aura.Tier, Color = displayColor, Mutated = mutated }
		AnnounceEvent:FireAllClients(ad)
		ChatAnnounceEvent:FireAllClients(ad)
	end
	
	StatsUpdatedEvent:FireClient(player, buildStats(data))
	return { Name = storedName, DisplayName = displayName, Rarity = aura.Rarity, Tier = aura.Tier, TotalRolls = data.Rolls, Color = displayColor, Mutated = mutated }
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
print("GameServer running! (V2 - Coin Economy Enabled)")
]==]

print("✅ SERVER ECONOMY UPDATE APPLIED!")
