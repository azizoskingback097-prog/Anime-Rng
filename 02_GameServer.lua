-- ═══════════════════════════════════════════════════════════
-- 🧠  GAME SERVER (v9)  —  Script   |   PLACE IN: ServerScriptService
-- ═══════════════════════════════════════════════════════════
-- 📝 WHAT IT DOES (simple words):
-- THE brain. Handles EVERYTHING server-side:
--   1. ROLLING      → roll auras (with weather mutations!)
--   2. INVENTORY    → what do I own?
--   3. EQUIP        → wear an aura
--   4. ADMIN        → give auras, give MUTATED auras, force WEATHER, set luck, reset
--   5. STATS        → tracks rolls, rarest pull, found
--   6. DATA SAVING  → DataStore
--
-- 🆕 NEW ADMIN ACTIONS (v9):
--   • "ForceWeather"  → instantly change the weather for everyone
--   • "GiveMutated"   → give yourself a mutated aura ("Sandy|Tempest")
--
-- 🎨 HOW TO CUSTOMIZE:
--   • Admins         → ADMIN_USERNAMES / ADMIN_IDS
--   • Roll speed     → ROLL_COOLDOWN
--   • Base luck      → LUCK
--
-- 🔗 RELATED SCRIPTS:
--   • AuraData       → aura list + roll algo
--   • WeatherData    → weather definitions (mutations, lighting, particles)
--   • WeatherServer  → weather cycling (reads CurrentWeather value)
--   • WeatherClient  → shows weather visuals (listens to WeatherChangedEvent)
--   • RollUI, InventoryUI, StatsUI, AdminUI → all talk to this
-- ═══════════════════════════════════════════════════════════

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local DataStoreService  = game:GetService("DataStoreService")
local AuraData    = require(ReplicatedStorage:WaitForChild("AuraData"))

-- ⚙️ CUSTOMIZE
local ADMIN_IDS        = { 12345678, 87654321 }
local ADMIN_USERNAMES  = { "Twix79i" }
local ROLL_COOLDOWN    = 0.5
local LUCK             = 1
local ANNOUNCE_RARITY  = 1000
local AUTO_EQUIP_FIRST = true
local AUTOSAVE_INTERVAL = 60
local DATASTORE_KEY    = "AnimeRNG_v1"

local Remotes              = ReplicatedStorage:WaitForChild("Remotes")
local RollFunction         = Remotes:WaitForChild("RollFunction")
local AnnounceEvent        = Remotes:WaitForChild("AnnounceEvent")
local GetInventoryFunction = Remotes:WaitForChild("GetInventoryFunction")
local EquipFunction        = Remotes:WaitForChild("EquipFunction")
local AdminFunction        = Remotes:WaitForChild("AdminFunction")
local GetStatsFunction     = Remotes:WaitForChild("GetStatsFunction")
local StatsUpdatedEvent    = Remotes:WaitForChild("StatsUpdatedEvent")
local AdminStatusEvent     = Remotes:WaitForChild("AdminStatusEvent")
local WeatherChangedEvent  = Remotes:WaitForChild("WeatherChangedEvent")
local currentWeatherValue  = ReplicatedStorage:WaitForChild("CurrentWeather")

local playerStore
pcall(function() playerStore = DataStoreService:GetDataStore(DATASTORE_KEY) end)

local PlayerData = {}
local lastRoll   = {}

local function isAdmin(player)
	for _, id in ipairs(ADMIN_IDS) do if player.UserId == id then return true end end
	local pname = string.lower(player.Name)
	local dname = string.lower(player.DisplayName)
	for _, name in ipairs(ADMIN_USERNAMES) do
		local lname = string.lower(name)
		if pname == lname or dname == lname then return true end
	end
	return false
end
local function newData()
	return { Inventory = {}, Equipped = nil, Rolls = 0, Luck = LUCK, RarestAura = "None", RarestRarity = 0 }
end
local function ensureFields(data)
	data.Inventory = data.Inventory or {}
	data.Equipped = data.Equipped or nil
	data.Rolls = data.Rolls or 0
	data.Luck = data.Luck or LUCK
	data.RarestAura = data.RarestAura or "None"
	data.RarestRarity = data.RarestRarity or 0
	return data
end
local function getData(player)
	if not PlayerData[player] then PlayerData[player] = newData() end
	return PlayerData[player]
end
local function buildStats(data)
	local unique = {}
	for _, name in ipairs(data.Inventory) do unique[name] = true end
	local found = 0
	for _ in pairs(unique) do found = found + 1 end
	return { Rolls = data.Rolls, RarestAura = data.RarestAura, RarestRarity = data.RarestRarity, Luck = data.Luck, Found = found, Total = #AuraData.Auras }
end
local function loadData(player)
	if playerStore then
		local key = "Player_" .. player.UserId
		local success, result = pcall(function() return playerStore:GetAsync(key) end)
		if success and result then PlayerData[player] = ensureFields(result)
		else PlayerData[player] = newData() end
	else PlayerData[player] = newData() end
	task.wait(0.5)
	if PlayerData[player] then StatsUpdatedEvent:FireClient(player, buildStats(PlayerData[player])) end
end
local function saveData(player)
	local data = PlayerData[player]
	if not data or not playerStore then return end
	local key = "Player_" .. player.UserId
	pcall(function() playerStore:SetAsync(key, data) end)
end

-- ────────────── 1) ROLLING (with mutations) ──────────────
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

	local weatherName = currentWeatherValue.Value
	if weatherName and weatherName ~= "Clear" then
		local WeatherData = require(ReplicatedStorage:WaitForChild("WeatherData"))
		local weather = WeatherData.GetByName(weatherName)
		if weather and weather.Mutation and weather.Mutation.Chance > 0 then
			if math.random() <= weather.Mutation.Chance then
				storedName = weather.Mutation.Name .. "|" .. aura.Name
				displayName = weather.Mutation.Name .. " " .. aura.Name
				displayColor = weather.Mutation.Color or aura.Color
				mutated = true
			end
		end
	end

	table.insert(data.Inventory, storedName)
	if aura.Rarity > data.RarestRarity then data.RarestRarity = aura.Rarity; data.RarestAura = displayName end
	if AUTO_EQUIP_FIRST and data.Equipped == nil then data.Equipped = storedName end

	if aura.Rarity >= ANNOUNCE_RARITY then
		AnnounceEvent:FireAllClients({ Player = player.Name, Name = displayName, Rarity = aura.Rarity, Tier = aura.Tier, Mutated = mutated })
	end
	StatsUpdatedEvent:FireClient(player, buildStats(data))
	return { Name = storedName, DisplayName = displayName, Rarity = aura.Rarity, Tier = aura.Tier, TotalRolls = data.Rolls, Color = displayColor, Mutated = mutated }
end

-- ────────────── 2) INVENTORY ──────────────
GetInventoryFunction.OnServerInvoke = function(player)
	local data = getData(player)
	local counts = {}
	for _, name in ipairs(data.Inventory) do counts[name] = (counts[name] or 0) + 1 end
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

-- ────────────── 4) ADMIN (with weather + mutated!) ──────────────
AdminFunction.OnServerInvoke = function(player, action, value)
	if not isAdmin(player) then return nil end
	local data = getData(player)

	if action == "IsAdmin" then
		return true

	elseif action == "GiveAura" then
		local aura = AuraData.GetByName(value)
		if not aura then return false end
		table.insert(data.Inventory, aura.Name)
		StatsUpdatedEvent:FireClient(player, buildStats(data))
		return true

	-- 🆕 GIVE MUTATED AURA — value = "Sandy|Tempest" format
	elseif action == "GiveMutated" then
		-- value should be "MutationName|AuraName"
		table.insert(data.Inventory, value)
		StatsUpdatedEvent:FireClient(player, buildStats(data))
		return true

	-- 🆕 FORCE WEATHER — instantly change weather for everyone!
	elseif action == "ForceWeather" then
		local WeatherData = require(ReplicatedStorage:WaitForChild("WeatherData"))
		local weather = WeatherData.GetByName(value)
		if not weather then return false end
		-- set the shared value (WeatherServer reads this)
		currentWeatherValue.Value = weather.Name
		-- fire the event to all clients so visuals update immediately
		WeatherChangedEvent:FireAllClients({
			Name = weather.Name,
			Lighting = weather.Lighting,
			Particles = weather.Particles,
			BannerText = weather.BannerText,
			BannerColor = weather.BannerColor,
		})
		print("🛠️ Admin forced weather: " .. weather.Name)
		return true

	-- 🆕 GET WEATHER LIST — returns all weather names for the admin UI
	elseif action == "GetWeatherList" then
		local WeatherData = require(ReplicatedStorage:WaitForChild("WeatherData"))
		local names = {}
		for _, w in ipairs(WeatherData.Weathers) do table.insert(names, w.Name) end
		return names

	elseif action == "SetLuck" then
		data.Luck = math.max(1, math.floor(tonumber(value) or 1))
		StatsUpdatedEvent:FireClient(player, buildStats(data))
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

	elseif action == "ResetData" then
		PlayerData[player] = newData()
		StatsUpdatedEvent:FireClient(player, buildStats(PlayerData[player]))
		return true
	end
	return nil
end

GetStatsFunction.OnServerInvoke = function(player) return buildStats(getData(player)) end

Players.PlayerAdded:Connect(function(player)
	loadData(player)
	task.wait(1.5)
	if isAdmin(player) then AdminStatusEvent:FireClient(player, true) end
end)
Players.PlayerRemoving:Connect(function(player) saveData(player); PlayerData[player] = nil; lastRoll[player] = nil end)
task.spawn(function() while true do task.wait(AUTOSAVE_INTERVAL) for p in pairs(PlayerData) do saveData(p) end end end)
game:BindToClose(function() for p in pairs(PlayerData) do saveData(p) end task.wait(2) end)
print("✅ GameServer v9 running! (Rolling + Mutations + Admin Weather + Admin Mutated + Inventory + Stats + DataStore)")
