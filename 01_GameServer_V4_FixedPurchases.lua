-- ═══════════════════════════════════════════════════════════
-- 🧠 GAMESERVER V4 (Fixed Purchases + Boosts Integrated)
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
-- ═══════════════════════════════════════════════════════════

local SSS = game:GetService("ServerScriptService")
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
local PurchaseItemFunction = Remotes:WaitForChild("PurchaseItemFunction")
local ShopOpenEvent = Remotes:WaitForChild("ShopOpenEvent")
local BoostUpdateEvent = Remotes:WaitForChild("BoostUpdateEvent")
local currentWeatherValue = ReplicatedStorage:WaitForChild("CurrentWeather")

local playerStore
pcall(function() playerStore = DataStoreService:GetDataStore(DATASTORE_KEY) end)
local PlayerData = {}
local lastRoll = {}

-- 🧪 BOOST DEFINITIONS (Add more items here!)
local SHOP_ITEMS = {
	["LuckPotion"] = { Price = 100000, Duration = 300, Type = "LuckMultiplier", Value = 2.0, Name = "x2 Luck Potion" },
	["CoinBoost"] = { Price = 200000, Duration = 300, Type = "CoinMultiplier", Value = 2.0, Name = "x2 Coins Boost" }
}

-- Active boosts: [player] = { LuckMultiplier = { expiresAt = 123.45 } }
local activeBoosts = {}

local function isAdmin(player)
	for _, id in ipairs(ADMIN_IDS) do if player.UserId == id then return true end end
	local pn = string.lower(player.Name); local dn = string.lower(player.DisplayName)
	for _, name in ipairs(ADMIN_USERNAMES) do
		if pn == string.lower(name) or dn == string.lower(name) then return true end
	end
	return false
end

local function newData()
	return { Inventory = {}, Equipped = nil, Rolls = 0, Luck = LUCK, RarestAura = "None", RarestRarity = 0, Coins = 0, Boosts = nil }
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

local function buildStats(d)
	local unique = {}
	for _, name in ipairs(d.Inventory) do unique[name] = true end
	local found = 0
	for _ in pairs(unique) do found = found + 1 end
	return { Rolls = d.Rolls, RarestAura = d.RarestAura, RarestRarity = d.RarestRarity, Luck = d.Luck, Found = found, Total = #AuraData.Auras, Coins = d.Coins }
end

-- 💰 NEW COIN FORMULA (15-20 min target)
local function calculateCoins(rarity)
	return math.floor(rarity * 5) + 50
end

local MUTATION_MULTIPLIERS = { Sandy = 1.25, Cosmic = 1.5, Cursed = 1.75 }

-- ═══ BOOST LOGIC ═══
local function notifyBoostClient(player)
	if not activeBoosts[player] then return end
	local clientData = {}
	for boostType, boostData in pairs(activeBoosts[player]) do
		local remaining = boostData.expiresAt - os.clock()
		if remaining > 0 then
			local value = 1.0
			for _, item in pairs(SHOP_ITEMS) do
				if item.Type == boostType then value = item.Value; break end
			end
			clientData[boostType] = { Remaining = remaining, Value = value }
		end
	end
	BoostUpdateEvent:FireClient(player, clientData)
end

local function getCoinMultiplier(player)
	if not activeBoosts[player] then return 1.0 end
	local boost = activeBoosts[player]["CoinMultiplier"]
	if not boost or os.clock() >= boost.expiresAt then return 1.0 end
	return SHOP_ITEMS["CoinBoost"].Value
end

local function getLuckMultiplier(player)
	if not activeBoosts[player] then return 1.0 end
	local boost = activeBoosts[player]["LuckMultiplier"]
	if not boost or os.clock() >= boost.expiresAt then return 1.0 end
	return SHOP_ITEMS["LuckPotion"].Value
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
		-- Load saved boosts (offline pause)
		if not activeBoosts[p] then activeBoosts[p] = {} end
		if PlayerData[p].Boosts then
			for boostType, data in pairs(PlayerData[p].Boosts) do
				if data.RemainingSeconds and data.RemainingSeconds > 0 then
					activeBoosts[p][boostType] = { expiresAt = os.clock() + data.RemainingSeconds }
				end
			end
		end
		notifyBoostClient(p)
	end
end

local function saveData(p)
	local d = PlayerData[p]; if not d or not playerStore then return end
	-- Save boosts (pause offline)
	if activeBoosts[p] then
		local toSave = {}
		for boostType, boostData in pairs(activeBoosts[p]) do
			local remaining = boostData.expiresAt - os.clock()
			if remaining > 0 then toSave[boostType] = { RemainingSeconds = remaining } end
		end
		d.Boosts = toSave
	end
	pcall(function() playerStore:SetAsync("Player_" .. p.UserId, d) end)
end

-- ═══ ROLL LOGIC ═══
RollFunction.OnServerInvoke = function(player)
	local now = os.clock()
	if lastRoll[player] and (now - lastRoll[player]) < ROLL_COOLDOWN then return nil end
	lastRoll[player] = now
	
	local data = getData(player)
	data.Rolls = data.Rolls + 1
	
	-- Check Luck Boost
	local effectiveLuck = data.Luck * getLuckMultiplier(player)
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
	
	-- Coin reward with boost
	local baseCoins = calculateCoins(aura.Rarity)
	if mutated and mutationName and MUTATION_MULTIPLIERS[mutationName] then
		baseCoins = math.floor(baseCoins * MUTATION_MULTIPLIERS[mutationName])
	end
	local finalCoins = math.floor(baseCoins * getCoinMultiplier(player))
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

-- ═══ PURCHASE LOGIC (FIXED!) ═══
PurchaseItemFunction.OnServerInvoke = function(player, itemId)
	local item = SHOP_ITEMS[itemId]
	if not item then return false, "Item not found!" end
	
	local data = getData(player)
	if data.Coins < item.Price then
		return false, "Not enough coins! Need " .. item.Price .. ", have " .. data.Coins
	end
	
	-- Deduct coins
	data.Coins = data.Coins - item.Price
	
	-- Apply boost (STACK TIME)
	if not activeBoosts[player] then activeBoosts[player] = {} end
	local boostType = item.Type
	if not activeBoosts[player][boostType] then
		activeBoosts[player][boostType] = { expiresAt = os.clock() + item.Duration }
	else
		local remaining = activeBoosts[player][boostType].expiresAt - os.clock()
		if remaining < 0 then remaining = 0 end
		activeBoosts[player][boostType].expiresAt = os.clock() + remaining + item.Duration
	end
	
	-- Update client
	StatsUpdatedEvent:FireClient(player, buildStats(data))
	notifyBoostClient(player)
	
	print("🧪 " .. player.Name .. " bought " .. itemId .. " for " .. item.Price .. " coins! Remaining: " .. data.Coins)
	return true, "Purchased " .. item.Name .. "!"
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
Players.PlayerRemoving:Connect(function(player) saveData(player); PlayerData[player] = nil; lastRoll[player] = nil; activeBoosts[player] = nil end)
task.spawn(function() while true do task.wait(AUTOSAVE_INTERVAL) for p in pairs(PlayerData) do saveData(p) end end end)
game:BindToClose(function() for p in pairs(PlayerData) do saveData(p) end task.wait(2) end)

-- Boost cleanup loop
task.spawn(function()
	while true do
		task.wait(10)
		for player, boosts in pairs(activeBoosts) do
			local changed = false
			for boostType, data in pairs(boosts) do
				if os.clock() >= data.expiresAt then
					boosts[boostType] = nil; changed = true
				end
			end
			if changed then notifyBoostClient(player) end
		end
	end
end)

print("✅ GameServer V4 running! (Purchases Fixed + Boosts Working)")
]==]

print("✅ GAMESERVER V4 DEPLOYED! (Purchase bug fixed!)")
