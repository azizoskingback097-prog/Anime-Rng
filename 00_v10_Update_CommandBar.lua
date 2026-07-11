-- ═══════════════════════════════════════════════════════════
-- 🛠️  v10 MASTER UPDATE — Teaching Comments + Skybox + Day/Night + Dual Announce
-- ═══════════════════════════════════════════════════════════
-- HOW TO USE:  View > Command Bar  →  paste ALL of this  →  Enter
--
-- Updates ALL 9 scripts with:
--   📚 Teaching comments on every customizable section
--   🌌 Skybox system (per-weather skybox support)
--   🌦️ Day/Night cycle (smooth, integrates with weather)
--   📢 Dual announcements (UI banner + chat, both rarity-colored)
--
-- NEW remotes: ChatAnnounceEvent
-- NEW shared value: none (reuses CurrentWeather)
-- ═══════════════════════════════════════════════════════════

local RS  = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")

local function ensure(className, name, parent)
	local inst = parent:FindFirstChild(name)
	if inst and inst.ClassName ~= className then inst:Destroy(); inst = nil end
	if not inst then inst = Instance.new(className); inst.Name = name; inst.Parent = parent end
	return inst
end

-- new remote for chat announcements
local remotes = RS:FindFirstChild("Remotes") or ensure("Folder", "Remotes", RS)
ensure("RemoteEvent", "ChatAnnounceEvent", remotes)

-- ═══ 1) AURA DATA ═══
ensure("ModuleScript", "AuraData", RS).Source = [==[
--[[
═══════════════════════════════════════════════════════════
📖 AURA DATA — The database of every aura in the game.
Read by: GameServer (rolling), RollUI (animation), InventoryUI,
AdminUI (give aura list).
═══════════════════════════════════════════════════════════
]]
local AuraData = {}

--[[
────────────────────────────────────────
📌 CUSTOMIZABLE SECTION: Aura List
HOW TO USE: Each { } is one aura. Copy one to add new.
  • Rarity = 1 in N (higher = rarer)
  • Color = shown in UI, inventory, chat announcements
  • Tier = label (Common/Rare/Legendary/Mythic)
EXAMPLE:
  { Name = "Rasengan", Rarity = 3000, Color = Color3.fromRGB(100,200,255), Tier = "Legendary" },
────────────────────────────────────────
]]
AuraData.Auras = {
	{ Name = "Flicker",  Rarity = 1,      Color = Color3.fromRGB(180,180,180), Tier = "Common"    },
	{ Name = "Spark",    Rarity = 4,      Color = Color3.fromRGB(120,200,255), Tier = "Common"    },
	{ Name = "Glow",     Rarity = 16,     Color = Color3.fromRGB(120,255,150), Tier = "Uncommon"  },
	{ Name = "Ember",    Rarity = 32,     Color = Color3.fromRGB(255,140,60),  Tier = "Uncommon"  },
	{ Name = "Surge",    Rarity = 128,    Color = Color3.fromRGB(80,120,255),  Tier = "Rare"      },
	{ Name = "Bloom",    Rarity = 256,    Color = Color3.fromRGB(255,90,200),  Tier = "Rare"      },
	{ Name = "Spirit Bomb",  Rarity = 500,    Color = Color3.fromRGB(80,160,255),  Tier = "Rare"   },
	{ Name = "Tempest",  Rarity = 1000,   Color = Color3.fromRGB(0,255,200),   Tier = "Epic"      },
	{ Name = "Nine-Tails",     Rarity = 5000,  Color = Color3.fromRGB(255,120,40),  Tier = "Legendary" },
	{ Name = "Eclipse",        Rarity = 7777,  Color = Color3.fromRGB(20,20,40),    Tier = "Legendary" },
	{ Name = "Conqueror Haki", Rarity = 8000,  Color = Color3.fromRGB(200,0,0),     Tier = "Legendary" },
	{ Name = "Cursed Energy",  Rarity = 12000, Color = Color3.fromRGB(60,0,90),     Tier = "Mythic"    },
	{ Name = "Hollow Mask",    Rarity = 20000, Color = Color3.fromRGB(245,245,245), Tier = "Mythic"    },
	{ Name = "Genesis",        Rarity = 70000, Color = Color3.fromRGB(255,255,200), Tier = "Mythic"    },
}

local function rollOnce()
	local totalWeight = 0
	for _, aura in ipairs(AuraData.Auras) do totalWeight = totalWeight + 1 / aura.Rarity end
	local r = math.random() * totalWeight
	local cumulative = 0
	for _, aura in ipairs(AuraData.Auras) do
		cumulative = cumulative + 1 / aura.Rarity
		if r <= cumulative then return aura end
	end
	return AuraData.Auras[1]
end
function AuraData.GetWeightedRandom(luck)
	luck = math.max(1, math.floor(luck or 1))
	local best = rollOnce()
	for _ = 2, luck do
		local attempt = rollOnce()
		if attempt.Rarity > best.Rarity then best = attempt end
	end
	return best
end
function AuraData.GetByName(name)
	for _, aura in ipairs(AuraData.Auras) do if aura.Name == name then return aura end end
	return nil
end
return AuraData
]==]

-- ═══ 2) WEATHER DATA (with TimeCycle) ═══
ensure("ModuleScript", "WeatherData", RS).Source = [==[
--[[
═══════════════════════════════════════════════════════════
🌪️ WEATHER DATA — Defines all weathers + day/night cycle.
Read by: WeatherServer, WeatherClient, GameServer (mutations).
═══════════════════════════════════════════════════════════
]]
local WeatherData = {}

--[[
────────────────────────────────────────
📌 CUSTOMIZABLE SECTION: Day/Night Cycle
HOW TO USE: Controls the continuous day/night transition.
  • DayDurationMinutes = real minutes per full 24h cycle
  • StartTime = hour to begin (0=midnight, 12=noon, 18=dusk)
  • DaySkybox/NightSkybox = optional {6 IDs} for sky textures
EXAMPLE:
  DayDurationMinutes = 5,  -- faster cycle
────────────────────────────────────────
]]
WeatherData.TimeCycle = {
	Enabled = true,
	DayDurationMinutes = 10,
	StartTime = 6,
	DaySkybox = nil,
	NightSkybox = nil,
}

--[[
────────────────────────────────────────
📌 CUSTOMIZABLE SECTION: Weather List
HOW TO USE: Copy a { } block to add a weather. Fields:
  Name, Weight (frequency), Duration {min,max} seconds,
  Mutation {Chance,Name,Color}, Lighting {...}, Skybox {6 IDs or nil},
  Particles {{...}}, BannerText, BannerColor
EXAMPLE — Blizzard:
  { Name="Blizzard", Weight=20, Duration={60,120},
    Mutation={Chance=0.12, Name="Frostbite", Color=Color3.fromRGB(150,220,255)},
    Lighting={ClockTime=11, FogColor=Color3.fromRGB(220,235,255), FogEnd=200, ...},
    Skybox=nil, Particles={{...}}, BannerText="❄️ BLIZZARD!", BannerColor=... }
────────────────────────────────────────
]]
WeatherData.Weathers = {
	{ Name="Clear", Weight=50, Duration={90,180},
	  Mutation={Chance=0, Name=nil, Color=nil},
	  Lighting={ClockTime=14, FogColor=Color3.fromRGB(199,217,240), FogEnd=100000,
	    Ambient=Color3.fromRGB(128,128,128), OutdoorAmbient=Color3.fromRGB(128,128,128),
	    Brightness=2, ColorShift_Top=Color3.fromRGB(0,0,0), ColorShift_Bottom=Color3.fromRGB(0,0,0)},
	  Skybox=nil, Particles={}, BannerText="", BannerColor=Color3.fromRGB(255,255,255) },
	{ Name="Sandstorm", Weight=25, Duration={60,120},
	  Mutation={Chance=0.10, Name="Sandy", Color=Color3.fromRGB(220,190,140)},
	  Lighting={ClockTime=12, FogColor=Color3.fromRGB(200,170,120), FogEnd=150,
	    Ambient=Color3.fromRGB(180,150,100), OutdoorAmbient=Color3.fromRGB(200,170,120),
	    Brightness=1.5, ColorShift_Top=Color3.fromRGB(40,30,10), ColorShift_Bottom=Color3.fromRGB(40,30,10)},
	  Skybox=nil,
	  Particles={{Color=Color3.fromRGB(210,180,140),
	    Size=NumberSequence.new({NumberSequenceKeypoint.new(0,4),NumberSequenceKeypoint.new(1,1)}),
	    Transparency=NumberSequence.new(0.4), Lifetime=NumberRange.new(4,7), Rate=300,
	    Speed=NumberRange.new(15,30), SpreadAngle=Vector2.new(45,45),
	    Acceleration=Vector3.new(30,0,0), Texture=""}},
	  BannerText="🌪️  SANDSTORM!  10% chance for SANDY mutations!",
	  BannerColor=Color3.fromRGB(220,190,140) },
	{ Name="Blood Moon", Weight=15, Duration={45,90},
	  Mutation={Chance=0.08, Name="Cursed", Color=Color3.fromRGB(150,0,30)},
	  Lighting={ClockTime=0, FogColor=Color3.fromRGB(40,0,10), FogEnd=300,
	    Ambient=Color3.fromRGB(80,10,20), OutdoorAmbient=Color3.fromRGB(60,0,15),
	    Brightness=1, ColorShift_Top=Color3.fromRGB(60,0,0), ColorShift_Bottom=Color3.fromRGB(40,0,0)},
	  Skybox=nil,
	  Particles={{Color=Color3.fromRGB(200,30,30),
	    Size=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,3)}),
	    Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.8),NumberSequenceKeypoint.new(1,0)}),
	    Lifetime=NumberRange.new(5,10), Rate=100, Speed=NumberRange.new(2,5),
	    SpreadAngle=Vector2.new(180,180), Acceleration=Vector3.new(0,-2,0), Texture=""}},
	  BannerText="🔴  BLOOD MOON!  8% chance for CURSED mutations!",
	  BannerColor=Color3.fromRGB(200,30,30) },
}

function WeatherData.GetByName(name)
	for _, w in ipairs(WeatherData.Weathers) do if w.Name == name then return w end end
	return nil
end
function WeatherData.GetByMutation(mutationName)
	for _, w in ipairs(WeatherData.Weathers) do
		if w.Mutation and w.Mutation.Name == mutationName then return w end
	end
	return nil
end
function WeatherData.PickRandom()
	local totalWeight = 0
	for _, w in ipairs(WeatherData.Weathers) do totalWeight = totalWeight + w.Weight end
	local r = math.random() * totalWeight
	local cumulative = 0
	for _, w in ipairs(WeatherData.Weathers) do
		cumulative = cumulative + w.Weight
		if r <= cumulative then return w end
	end
	return WeatherData.Weathers[1]
end
return WeatherData
]==]

-- ═══ 3) GAME SERVER (with Color in announce + teaching comments) ═══
ensure("Script", "GameServer", SSS).Source = [==[
--[[
═══════════════════════════════════════════════════════════
🧠 GAME SERVER — THE brain. Handles rolling, mutations,
inventory, equip, admin (incl. weather/mutated), stats, saving.
═══════════════════════════════════════════════════════════
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local AuraData = require(ReplicatedStorage:WaitForChild("AuraData"))

--[[
────────────────────────────────────────
📌 CUSTOMIZABLE SECTION: Settings
HOW TO USE: Edit these values to change game behavior.
  • ADMIN_USERNAMES = add Roblox usernames who get admin panel
  • ADMIN_IDS = add Roblox UserIds (alternative to usernames)
  • ROLL_COOLDOWN = seconds between rolls (anti-spam)
  • LUCK = global base luck (N = roll N times, keep rarest)
  • ANNOUNCE_RARITY = pulls this rare+ get announced (UI + chat)
EXAMPLE:
  ADMIN_USERNAMES = { "Twix79i", "YourFriend" },
  ANNOUNCE_RARITY = 500,  -- announce more often
────────────────────────────────────────
]]
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
local ChatAnnounceEvent    = Remotes:WaitForChild("ChatAnnounceEvent")
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
local lastRoll = {}

local function isAdmin(player)
	for _, id in ipairs(ADMIN_IDS) do if player.UserId == id then return true end end
	local pn = string.lower(player.Name); local dn = string.lower(player.DisplayName)
	for _, name in ipairs(ADMIN_USERNAMES) do
		local ln = string.lower(name)
		if pn == ln or dn == ln then return true end
	end
	return false
end
local function newData() return { Inventory = {}, Equipped = nil, Rolls = 0, Luck = LUCK, RarestAura = "None", RarestRarity = 0 } end
local function ensureFields(d)
	d.Inventory = d.Inventory or {}; d.Equipped = d.Equipped or nil; d.Rolls = d.Rolls or 0
	d.Luck = d.Luck or LUCK; d.RarestAura = d.RarestAura or "None"; d.RarestRarity = d.RarestRarity or 0
	return d
end
local function getData(p) if not PlayerData[p] then PlayerData[p] = newData() end return PlayerData[p] end
local function buildStats(d)
	local u = {}; for _, n in ipairs(d.Inventory) do u[n] = true end
	local f = 0; for _ in pairs(u) do f = f + 1 end
	return { Rolls=d.Rolls, RarestAura=d.RarestAura, RarestRarity=d.RarestRarity, Luck=d.Luck, Found=f, Total=#AuraData.Auras }
end
local function loadData(p)
	if playerStore then
		local k = "Player_" .. p.UserId
		local s, r = pcall(function() return playerStore:GetAsync(k) end)
		if s and r then PlayerData[p] = ensureFields(r) else PlayerData[p] = newData() end
	else PlayerData[p] = newData() end
	task.wait(0.5)
	if PlayerData[p] then StatsUpdatedEvent:FireClient(p, buildStats(PlayerData[p])) end
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
			end
		end
	end

	table.insert(data.Inventory, storedName)
	if aura.Rarity > data.RarestRarity then data.RarestRarity = aura.Rarity; data.RarestAura = displayName end
	if AUTO_EQUIP_FIRST and data.Equipped == nil then data.Equipped = storedName end

	-- 📢 DUAL ANNOUNCEMENT: fire both UI event AND chat event with rarity color
	if aura.Rarity >= ANNOUNCE_RARITY then
		local announceData = {
			Player = player.Name, Name = displayName, Rarity = aura.Rarity,
			Tier = aura.Tier, Color = displayColor, Mutated = mutated,
		}
		AnnounceEvent:FireAllClients(announceData)
		ChatAnnounceEvent:FireAllClients(announceData)
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
	for _, name in ipairs(data.Inventory) do if name == auraName then data.Equipped = auraName; return true end end
	return false
end

AdminFunction.OnServerInvoke = function(player, action, value)
	if not isAdmin(player) then return nil end
	local data = getData(player)
	if action == "IsAdmin" then return true
	elseif action == "GiveAura" then
		local aura = AuraData.GetByName(value)
		if not aura then return false end
		table.insert(data.Inventory, aura.Name)
		StatsUpdatedEvent:FireClient(player, buildStats(data)); return true
	elseif action == "GiveMutated" then
		table.insert(data.Inventory, value)
		StatsUpdatedEvent:FireClient(player, buildStats(data)); return true
	elseif action == "ForceWeather" then
		local WeatherData = require(ReplicatedStorage:WaitForChild("WeatherData"))
		local weather = WeatherData.GetByName(value)
		if not weather then return false end
		currentWeatherValue.Value = weather.Name
		WeatherChangedEvent:FireAllClients({
			Name = weather.Name, Lighting = weather.Lighting, Particles = weather.Particles,
			Skybox = weather.Skybox, BannerText = weather.BannerText, BannerColor = weather.BannerColor,
		})
		return true
	elseif action == "SetLuck" then
		data.Luck = math.max(1, math.floor(tonumber(value) or 1))
		StatsUpdatedEvent:FireClient(player, buildStats(data)); return data.Luck
	elseif action == "GiveRare" then
		local aura = AuraData.GetWeightedRandom(5000)
		table.insert(data.Inventory, aura.Name)
		StatsUpdatedEvent:FireClient(player, buildStats(data)); return aura.Name
	elseif action == "ClearInventory" then
		data.Inventory = {}; data.Equipped = nil
		StatsUpdatedEvent:FireClient(player, buildStats(data)); return true
	elseif action == "ResetData" then
		PlayerData[player] = newData()
		StatsUpdatedEvent:FireClient(player, buildStats(PlayerData[player])); return true
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
print("✅ GameServer v10 running! (Dual Announce + Mutations + Admin Weather)")
]==]

-- ═══ 4) WEATHER SERVER ═══
ensure("Script", "WeatherServer", SSS).Source = [==[
--[[
═══════════════════════════════════════════════════════════
🌪️ WEATHER SERVER — Cycles weather + posts chat tips.
Detects admin-forced weather changes and resets timer.
═══════════════════════════════════════════════════════════
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local WeatherData = require(ReplicatedStorage:WaitForChild("WeatherData"))

--[[
────────────────────────────────────────
📌 CUSTOMIZABLE SECTION: Chat Tips
HOW TO USE: Add/remove messages in the TIPS list.
They show randomly in chat every TIP_INTERVAL seconds.
EXAMPLE:
  "💡 New aura dropped: Void Reaper — can you roll it?",
────────────────────────────────────────
]]
local START_DELAY = 5
local TIP_INTERVAL = 60
local TIPS = {
	"💡 Don't forget to LIKE and FAVORITE the game!",
	"💡 Special weather can MUTATE your auras — watch the sky!",
	"💡 Check the shop for luck potions to boost your rolls!",
	"💡 The rarer the aura, the cooler it looks — keep rolling!",
	"💡 Blood Moon weather gives CURSED mutations!",
	"💡 Sandstorm weather gives SANDY mutations!",
	"💡 Equip your best aura from the Inventory!",
	"💡 Trade with friends to complete your collection!",
}

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local WeatherChangedEvent = Remotes:WaitForChild("WeatherChangedEvent")
local ChatTipEvent = Remotes:WaitForChild("ChatTipEvent")
local currentWeatherValue = ReplicatedStorage:WaitForChild("CurrentWeather")

local function applyWeather(weather)
	currentWeatherValue.Value = weather.Name
	WeatherChangedEvent:FireAllClients({
		Name = weather.Name, Lighting = weather.Lighting, Particles = weather.Particles,
		Skybox = weather.Skybox, BannerText = weather.BannerText, BannerColor = weather.BannerColor,
	})
	if weather.Name ~= "Clear" then print("🌪️ Weather: " .. weather.Name) end
end

task.spawn(function()
	task.wait(START_DELAY)
	while true do
		local tip = TIPS[math.random(1, #TIPS)]
		for _, player in ipairs(Players:GetPlayers()) do ChatTipEvent:FireClient(player, tip) end
		task.wait(TIP_INTERVAL)
	end
end)

currentWeatherValue.Value = "Clear"
task.wait(START_DELAY)
while true do
	local weather = WeatherData.PickRandom()
	applyWeather(weather)
	local duration = math.random(weather.Duration[1], weather.Duration[2])
	local appliedName = weather.Name
	local elapsed = 0
	while elapsed < duration do
		task.wait(1); elapsed = elapsed + 1
		if currentWeatherValue.Value ~= appliedName then
			appliedName = currentWeatherValue.Value
			local forced = WeatherData.GetByName(appliedName)
			if forced then duration = math.random(forced.Duration[1], forced.Duration[2]) end
			elapsed = 0
		end
	end
end
]==]

-- ═══ 5) WEATHER CLIENT (with day/night + skybox + chat announce) ═══
ensure("LocalScript", "WeatherClient", SPS).Source = [==[
--[[
═══════════════════════════════════════════════════════════
🌪️ WEATHER CLIENT — Shows weather visuals:
  • Lighting transitions (smooth tweens)
  • Particle VFX (follows player)
  • Skybox rendering (creates Sky object in Lighting)
  • Day/Night cycle (advances ClockTime when weather is Clear)
  • Chat announcements (rarity-colored, from GameServer)
  • Chat tips (from WeatherServer)
═══════════════════════════════════════════════════════════
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local WeatherChangedEvent = Remotes:WaitForChild("WeatherChangedEvent")
local ChatTipEvent = Remotes:WaitForChild("ChatTipEvent")
local ChatAnnounceEvent = Remotes:WaitForChild("ChatAnnounceEvent")
local WeatherData = require(ReplicatedStorage:WaitForChild("WeatherData"))

--[[
────────────────────────────────────────
📌 CUSTOMIZABLE SECTION: Display Settings
HOW TO USE: Tweak how weather visuals appear.
  • VFX_HEIGHT = how far above the player particles spawn (studs)
  • TWEEN_TIME = seconds for lighting to transition (smoothness)
  • BANNER_DURATION = seconds the weather banner stays visible
────────────────────────────────────────
]]
local VFX_HEIGHT = 50
local TWEEN_TIME = 3
local BANNER_DURATION = 5

-- self-clean
for _, c in ipairs(playerGui:GetChildren()) do if c.Name == "WeatherGui" then c:Destroy() end end
local gui = Instance.new("ScreenGui")
gui.Name = "WeatherGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 15; gui.Parent = playerGui

local banner = Instance.new("TextLabel")
banner.Size = UDim2.fromScale(0.7, 0.08); banner.Position = UDim2.fromScale(0.15, 0.04)
banner.Text = ""; banner.Font = Enum.Font.GothamBlack; banner.TextScaled = true
banner.BackgroundColor3 = Color3.fromRGB(20,20,35); banner.TextColor3 = Color3.fromRGB(255,255,255)
banner.BackgroundTransparency = 1; banner.Visible = false
local bnCorner = Instance.new("UICorner"); bnCorner.CornerRadius = UDim.new(0.15,0); bnCorner.Parent = banner; banner.Parent = gui

local currentVFX = nil
local weatherOverride = false  -- true when non-Clear weather controls lighting

local function clearVFX() if currentVFX then currentVFX:Destroy(); currentVFX = nil end end

local function applyVFX(particles)
	clearVFX()
	if not particles or #particles == 0 then return end
	local char = player.Character; if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
	currentVFX = Instance.new("Part")
	currentVFX.Name = "WeatherVFX"; currentVFX.Size = Vector3.new(1,1,1); currentVFX.Transparency = 1
	currentVFX.CanCollide = false; currentVFX.CanQuery = false; currentVFX.Anchored = false; currentVFX.Massless = true
	local weld = Instance.new("Weld"); weld.Part0 = root; weld.Part1 = currentVFX; weld.C0 = CFrame.new(0, VFX_HEIGHT, 0); weld.Parent = currentVFX
	currentVFX.Parent = char
	for _, cfg in ipairs(particles) do
		local e = Instance.new("ParticleEmitter")
		e.Color = ColorSequence.new(cfg.Color or Color3.fromRGB(255,255,255))
		e.Size = cfg.Size or NumberSequence.new(2)
		e.Transparency = cfg.Transparency or NumberSequence.new(0)
		e.Lifetime = cfg.Lifetime or NumberRange.new(5,10)
		e.Rate = cfg.Rate or 100; e.Speed = cfg.Speed or NumberRange.new(5,10)
		e.SpreadAngle = cfg.SpreadAngle or Vector2.new(45,45)
		e.Acceleration = cfg.Acceleration or Vector3.new(0,0,0)
		if cfg.Texture and cfg.Texture ~= "" then e.Texture = cfg.Texture end
		e.Parent = currentVFX
	end
end

-- 🌌 SKYBOX: create/update Sky object in Lighting
local function applySkybox(skyboxIds)
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if not sky then sky = Instance.new("Sky"); sky.Parent = Lighting end
	if skyboxIds and #skyboxIds == 6 then
		sky.SkyboxBk = skyboxIds[1]; sky.SkyboxDn = skyboxIds[2]; sky.SkyboxFt = skyboxIds[3]
		sky.SkyboxLf = skyboxIds[4]; sky.SkyboxRt = skyboxIds[5]; sky.SkyboxUp = skyboxIds[6]
		sky.CelestialBodiesShow = true
	end
end

local function applyLighting(lightingCfg)
	if not lightingCfg then return end
	TweenService:Create(Lighting, TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		ClockTime = lightingCfg.ClockTime or 14,
		FogColor = lightingCfg.FogColor or Color3.fromRGB(199,217,240),
		FogEnd = lightingCfg.FogEnd or 100000,
		Ambient = lightingCfg.Ambient or Color3.fromRGB(128,128,128),
		OutdoorAmbient = lightingCfg.OutdoorAmbient or Color3.fromRGB(128,128,128),
		Brightness = lightingCfg.Brightness or 2,
		ColorShift_Top = lightingCfg.ColorShift_Top or Color3.fromRGB(0,0,0),
		ColorShift_Bottom = lightingCfg.ColorShift_Bottom or Color3.fromRGB(0,0,0),
	}):Play()
end

local function showBanner(text, color)
	if not text or text == "" then return end
	banner.Text = text; banner.TextColor3 = color or Color3.fromRGB(255,255,255)
	banner.Visible = true; banner.BackgroundTransparency = 0.3; banner.TextTransparency = 0
	banner.Position = UDim2.fromScale(0.15, -0.1)
	TweenService:Create(banner, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.15, 0.04)}):Play()
	task.delay(BANNER_DURATION, function()
		TweenService:Create(banner, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
		task.wait(0.5); banner.Visible = false
	end)
end

WeatherChangedEvent.OnClientEvent:Connect(function(info)
	weatherOverride = (info.Name ~= "Clear")
	applyLighting(info.Lighting)
	applyVFX(info.Particles)
	applySkybox(info.Skybox)
	showBanner(info.BannerText, info.BannerColor)
end)

-- 🌦️ DAY/NIGHT CYCLE: advances ClockTime when weather is Clear
local tc = WeatherData.TimeCycle
if tc.Enabled then
	Lighting.ClockTime = tc.StartTime or 6
	local hoursPerSec = 24 / ((tc.DayDurationMinutes or 10) * 60)
	task.spawn(function()
		while true do
			if not weatherOverride then
				Lighting.ClockTime = (Lighting.ClockTime + hoursPerSec * 0.1) % 24
				-- optional day/night skybox switching
				if tc.DaySkybox and tc.NightSkybox then
					local h = Lighting.ClockTime
					if h > 6 and h < 18 then applySkybox(tc.DaySkybox) else applySkybox(tc.NightSkybox) end
				end
			end
			task.wait(0.1)
		end
	end)
end

player.CharacterAdded:Connect(function()
	task.wait(1)
	local cv = ReplicatedStorage:FindFirstChild("CurrentWeather")
	if cv and cv.Value ~= "Clear" then
		local weather = WeatherData.GetByName(cv.Value)
		if weather then applyVFX(weather.Particles) end
	end
end)

-- chat tips
ChatTipEvent.OnClientEvent:Connect(function(message)
	pcall(function() StarterGui:SetCore("ChatMakeSystemMessage", { Text = message, Color = Color3.fromRGB(255,215,0), Font = Enum.Font.SourceSansBold, TextSize = 18 }) end)
end)

-- 📢 CHAT ANNOUNCEMENTS (rarity-colored!)
ChatAnnounceEvent.OnClientEvent:Connect(function(info)
	pcall(function()
		StarterGui:SetCore("ChatMakeSystemMessage", {
			Text = "⭐ " .. info.Player .. " has obtained " .. info.Name .. "! (" .. info.Tier .. ")",
			Color = info.Color or Color3.fromRGB(255, 215, 0),
			Font = Enum.Font.SourceSansBold,
			TextSize = 18,
		})
	end)
end)

print("🌪️ WeatherClient v10 loaded! (Day/Night + Skybox + Chat Announce)")
]==]

-- ═══ 6) ROLL UI (rarity-colored banner) ═══
ensure("LocalScript", "RollUI", SPS).Source = [==[
--[[
═══════════════════════════════════════════════════════════
🖥️ ROLL UI — Cinematic roll animation + rare-pull banner.
Animation: flicker → near-miss → flash → reveal → shake.
Banner: rarity-colored, shows who pulled what.
═══════════════════════════════════════════════════════════
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RollFunction = Remotes:WaitForChild("RollFunction")
local AnnounceEvent = Remotes:WaitForChild("AnnounceEvent")
local AuraData = require(ReplicatedStorage:WaitForChild("AuraData"))
local auraNames = {}
for _, a in ipairs(AuraData.Auras) do table.insert(auraNames, a.Name) end

--[[
────────────────────────────────────────
📌 CUSTOMIZABLE SECTION: UI Theme & Animation
HOW TO USE: Edit colors, animation speeds, and effects.
  • FLICKER_SPEEDS = how fast names cycle (decelerating)
  • NEAR_MISS_HOLD = seconds to hold the fake rare aura
  • FLASH_TIME = white flash duration (masks the swap)
  • SHAKE_THRESHOLD = pulls this rare+ get a shake
EXAMPLE:
  NEAR_MISS_HOLD = 1.0,  -- longer suspense
────────────────────────────────────────
]]
local TEXT_COLOR = Color3.fromRGB(255,255,255)
local BANNER_DEFAULT_COLOR = Color3.fromRGB(255,215,0)
local THEME_COLOR = Color3.fromRGB(30,30,45)
local ROLL_BUTTON_COLOR = Color3.fromRGB(80,120,255)
local FLICKER_SPEEDS = {0.03,0.035,0.04,0.045,0.05,0.06,0.07,0.085,0.10,0.12}
local NEAR_MISS_RARITY = 1000
local NEAR_MISS_HOLD = 0.6
local FLASH_TIME = 0.25
local GLOW_STROKE = 0.2
local SHAKE_THRESHOLD = 1000
local SHAKE_INTENSITY = 0.012
local SHAKE_DURATION = 0.4
local RESULT_HOME = UDim2.fromScale(0.2,0.36)
local NEAR_MISS_SIZE = UDim2.fromScale(0.7,0.32)

local rareAuras = {}
for _, a in ipairs(AuraData.Auras) do if a.Rarity >= NEAR_MISS_RARITY then table.insert(rareAuras, a) end end

for _, c in ipairs(playerGui:GetChildren()) do if c.Name == "RollGui" then c:Destroy() end end
local gui = Instance.new("ScreenGui")
gui.Name = "RollGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 10; gui.Parent = playerGui

local button = Instance.new("TextButton")
button.Size = UDim2.fromScale(0.16,0.09); button.Position = UDim2.fromScale(0.81,0.87)
button.Text = "ROLL"; button.Font = Enum.Font.GothamBlack; button.TextScaled = true
button.BackgroundColor3 = ROLL_BUTTON_COLOR; button.TextColor3 = TEXT_COLOR
local bCorner = Instance.new("UICorner"); bCorner.CornerRadius = UDim.new(0.12,0); bCorner.Parent = button; button.Parent = gui

local result = Instance.new("TextLabel")
result.Size = UDim2.fromScale(0.6,0.22); result.Position = RESULT_HOME
result.Text = "Press ROLL to begin!"; result.Font = Enum.Font.GothamBlack; result.TextScaled = true
result.BackgroundTransparency = 1; result.TextColor3 = TEXT_COLOR; result.TextStrokeTransparency = 1; result.Parent = gui

local banner = Instance.new("TextLabel")
banner.Size = UDim2.fromScale(0.7,0.1); banner.Position = UDim2.fromScale(0.15,0.12)
banner.Text = ""; banner.Font = Enum.Font.GothamBlack; banner.TextScaled = true
banner.BackgroundColor3 = THEME_COLOR; banner.TextColor3 = BANNER_DEFAULT_COLOR
banner.BackgroundTransparency = 1; banner.Visible = false
local bnCorner = Instance.new("UICorner"); bnCorner.CornerRadius = UDim.new(0.2,0); bnCorner.Parent = banner; banner.Parent = gui

local flash = Instance.new("Frame")
flash.Size = UDim2.fromScale(1,1); flash.Position = UDim2.fromScale(0,0)
flash.BackgroundColor3 = Color3.fromRGB(255,255,255); flash.BackgroundTransparency = 1; flash.ZIndex = 50; flash.Parent = gui

local function setGlow(on) result.TextStrokeColor3 = result.TextColor3; result.TextStrokeTransparency = on and GLOW_STROKE or 1 end
local function shakeLabel(label, homePos, rarity)
	local intensity = SHAKE_INTENSITY; local duration = SHAKE_DURATION
	if rarity >= 5000 then intensity = SHAKE_INTENSITY*1.5; duration = SHAKE_DURATION*1.4 end
	if rarity >= 70000 then intensity = SHAKE_INTENSITY*2.2; duration = SHAKE_DURATION*1.8 end
	local startTime = os.clock()
	while os.clock() - startTime < duration do
		label.Position = UDim2.fromScale(homePos.X.Scale+(math.random()-0.5)*2*intensity, homePos.Y.Scale+(math.random()-0.5)*2*intensity)
		task.wait(0.02)
	end
	label.Position = homePos
end

local isRolling = false
button.MouseButton1Click:Connect(function()
	if isRolling then return end
	isRolling = true; button.Text = "..."
	result.Text = ""; result.TextColor3 = TEXT_COLOR; result.Position = RESULT_HOME; result.Size = UDim2.fromScale(0.6,0.22); setGlow(false)
	local gotResult = false; local res
	task.spawn(function() res = RollFunction:InvokeServer(); gotResult = true end)
	for _, speed in ipairs(FLICKER_SPEEDS) do result.Text = auraNames[math.random(1,#auraNames)]; task.wait(speed) end
	if #rareAuras > 0 then
		local fake = rareAuras[math.random(1,#rareAuras)]
		result.TextColor3 = fake.Color; setGlow(true)
		result.Text = fake.Name .. "\n1 in " .. fake.Rarity .. "  •  " .. fake.Tier
		result.Size = NEAR_MISS_SIZE; result.Position = UDim2.fromScale(0.15,0.34)
		TweenService:Create(result, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.15,0.30)}):Play()
		task.wait(NEAR_MISS_HOLD)
	end
	flash.BackgroundTransparency = 1
	local flashIn = TweenService:Create(flash, TweenInfo.new(FLASH_TIME*0.4), {BackgroundTransparency = 0})
	flashIn:Play(); flashIn.Completed:Wait()
	setGlow(false); result.Size = UDim2.fromScale(0.6,0.22)
	while not gotResult do task.wait(0.02) end
	button.Text = "ROLL"
	if not res then
		result.Text = "⏳ Too fast!"; result.TextColor3 = TEXT_COLOR
		TweenService:Create(flash, TweenInfo.new(FLASH_TIME), {BackgroundTransparency = 1}):Play()
		isRolling = false; return
	end
	local displayText = res.DisplayName or res.Name
	if res.Mutated then displayText = "✨ MUTATED ✨\n" .. displayText end
	result.Text = displayText .. "\n1 in " .. res.Rarity .. "  •  " .. res.Tier
	result.TextColor3 = res.Color or TEXT_COLOR
	result.Position = UDim2.fromScale(0.2,-0.3)
	TweenService:Create(flash, TweenInfo.new(FLASH_TIME), {BackgroundTransparency = 1}):Play()
	local reveal = TweenService:Create(result, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = RESULT_HOME})
	reveal:Play(); reveal.Completed:Wait()
	if res.Rarity >= SHAKE_THRESHOLD or res.Mutated then setGlow(true); shakeLabel(result, RESULT_HOME, res.Rarity) end
	isRolling = false
end)

-- 📢 UI ANNOUNCEMENT (rarity-colored!)
AnnounceEvent.OnClientEvent:Connect(function(info)
	local prefix = info.Mutated and "✨ MUTATED " or ""
	banner.Text = "🎉  " .. info.Player .. " pulled " .. prefix .. info.Name .. "  (1 in " .. info.Rarity .. ")!"
	-- use the rarity color sent from the server
	banner.TextColor3 = info.Color or BANNER_DEFAULT_COLOR
	banner.Visible = true; banner.BackgroundTransparency = 0.3; banner.Position = UDim2.fromScale(0.15,-0.15)
	TweenService:Create(banner, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.15,0.12)}):Play()
	task.delay(5, function() banner.Visible = false end)
end)
]==]

-- ═══ 7) INVENTORY UI ═══
ensure("LocalScript", "InventoryUI", SPS).Source = [==[
--[[
═══════════════════════════════════════════════════════════
🎒 INVENTORY UI — View & equip your auras.
Shows mutated auras separately with unique colors.
═══════════════════════════════════════════════════════════
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetInventoryFunction = Remotes:WaitForChild("GetInventoryFunction")
local EquipFunction = Remotes:WaitForChild("EquipFunction")
local AuraData = require(ReplicatedStorage:WaitForChild("AuraData"))

--[[
────────────────────────────────────────
📌 CUSTOMIZABLE SECTION: Colors & Layout
HOW TO USE: Edit colors or layout below.
  • ITEMS_PER_ROW = how many items per row in the grid
  • BG_COLOR = window background color
EXAMPLE:
  ITEMS_PER_ROW = 5,  -- more items per row
────────────────────────────────────────
]]
local BG_COLOR = Color3.fromRGB(25,25,40)
local ITEM_COLOR = Color3.fromRGB(45,45,65)
local MUTATION_ITEM_COLOR = Color3.fromRGB(60,40,70)
local TEXT_COLOR = Color3.fromRGB(255,255,255)
local EQUIPPED_COLOR = Color3.fromRGB(80,200,120)
local BUTTON_COLOR = Color3.fromRGB(80,120,255)
local ITEMS_PER_ROW = 4

for _, c in ipairs(playerGui:GetChildren()) do if c.Name == "InventoryGui" then c:Destroy() end end
local gui = Instance.new("ScreenGui")
gui.Name = "InventoryGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 20; gui.Parent = playerGui

local openBtn = Instance.new("TextButton")
openBtn.Size = UDim2.fromScale(0.16,0.06); openBtn.Position = UDim2.fromScale(0.81,0.76)
openBtn.Text = "🎒  Inventory"; openBtn.Font = Enum.Font.GothamBold; openBtn.TextScaled = true
openBtn.BackgroundColor3 = BUTTON_COLOR; openBtn.TextColor3 = TEXT_COLOR
local obCorner = Instance.new("UICorner"); obCorner.CornerRadius = UDim.new(0.15,0); obCorner.Parent = openBtn; openBtn.Parent = gui

local window = Instance.new("Frame")
window.Size = UDim2.fromScale(0.55,0.62); window.Position = UDim2.fromScale(0.225,0.19)
window.BackgroundColor3 = BG_COLOR; window.Visible = false
local wCorner = Instance.new("UICorner"); wCorner.CornerRadius = UDim.new(0.04,0); wCorner.Parent = window
local wStroke = Instance.new("UIStroke"); wStroke.Thickness = 2; wStroke.Color = Color3.fromRGB(80,120,255); wStroke.Parent = window; window.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.fromScale(1,0.1); title.Position = UDim2.fromScale(0,0.02)
title.Text = "🎒  Your Auras"; title.Font = Enum.Font.GothamBlack; title.TextScaled = true
title.BackgroundTransparency = 1; title.TextColor3 = TEXT_COLOR; title.Parent = window

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromScale(0.07,0.09); closeBtn.Position = UDim2.fromScale(0.9,0.015)
closeBtn.Text = "✕"; closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextScaled = true
closeBtn.BackgroundColor3 = Color3.fromRGB(200,60,60); closeBtn.TextColor3 = TEXT_COLOR
local cbCorner = Instance.new("UICorner"); cbCorner.CornerRadius = UDim.new(0.2,0); cbCorner.Parent = closeBtn; closeBtn.Parent = window

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.fromScale(0.94,0.82); scroll.Position = UDim2.fromScale(0.03,0.13)
scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 6
scroll.CanvasSize = UDim2.fromScale(0,0); scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; scroll.Parent = window

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.fromScale(0.23,0.18); grid.CellPadding = UDim2.fromScale(0.02,0.02)
grid.SortOrder = Enum.SortOrder.LayoutOrder; grid.Parent = scroll

local function parseAuraName(stored)
	local sep = string.find(stored, "|")
	if sep then return { Mutation = string.sub(stored,1,sep-1), Base = string.sub(stored,sep+1), Display = string.sub(stored,1,sep-1) .. " " .. string.sub(stored,sep+1) } end
	return { Mutation = nil, Base = stored, Display = stored }
end
local function getMutationColor(mutName)
	local WeatherData = require(ReplicatedStorage:WaitForChild("WeatherData"))
	local w = WeatherData.GetByMutation(mutName)
	if w and w.Mutation and w.Mutation.Color then return w.Mutation.Color end
	return nil
end

local isOpen = false
local function refresh()
	for _, c in ipairs(scroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
	local data = GetInventoryFunction:InvokeServer()
	if not data or not data.Counts then return end
	local equipped = data.Equipped
	local names = {}
	for name in pairs(data.Counts) do table.insert(names, name) end
	table.sort(names, function(a,b)
		local pa = parseAuraName(a); local pb = parseAuraName(b)
		local ra = AuraData.GetByName(pa.Base); local rb = AuraData.GetByName(pb.Base)
		local raV = (ra and ra.Rarity or 0); local rbV = (rb and rb.Rarity or 0)
		if raV == rbV then if pa.Mutation and not pb.Mutation then return true end if not pa.Mutation and pb.Mutation then return false end end
		return raV > rbV
	end)
	for _, name in ipairs(names) do
		local parsed = parseAuraName(name)
		local aura = AuraData.GetByName(parsed.Base); local count = data.Counts[name]
		local item = Instance.new("TextButton")
		item.Text = parsed.Display .. "\n(×" .. count .. ")"
		item.Font = Enum.Font.GothamBold; item.TextScaled = true
		if parsed.Mutation then
			item.BackgroundColor3 = MUTATION_ITEM_COLOR
			item.TextColor3 = getMutationColor(parsed.Mutation) or (aura and aura.Color) or TEXT_COLOR
		else
			item.BackgroundColor3 = ITEM_COLOR; item.TextColor3 = (aura and aura.Color) or TEXT_COLOR
		end
		if name == equipped then
			item.BackgroundColor3 = EQUIPPED_COLOR; item.Text = "✓ " .. parsed.Display .. "\n(×" .. count .. ")"
			local eStroke = Instance.new("UIStroke"); eStroke.Thickness = 3; eStroke.Color = Color3.fromRGB(255,255,255); eStroke.Parent = item
		end
		local iCorner = Instance.new("UICorner"); iCorner.CornerRadius = UDim.new(0.15,0); iCorner.Parent = item; item.Parent = scroll
		item.MouseButton1Click:Connect(function() EquipFunction:InvokeServer(name); refresh() end)
	end
end
openBtn.MouseButton1Click:Connect(function() isOpen = not isOpen; window.Visible = isOpen; if isOpen then refresh() end end)
closeBtn.MouseButton1Click:Connect(function() isOpen = false; window.Visible = false end)
]==]

-- ═══ 8) STATS UI ═══
ensure("LocalScript", "StatsUI", SPS).Source = [==[
--[[
═══════════════════════════════════════════════════════════
📊 STATS UI — Always-visible stats panel (top-right).
Shows: Rolls, Rarest Pull, Auras Found, Luck.
═══════════════════════════════════════════════════════════
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetStatsFunction = Remotes:WaitForChild("GetStatsFunction")
local StatsUpdatedEvent = Remotes:WaitForChild("StatsUpdatedEvent")

--[[
────────────────────────────────────────
📌 CUSTOMIZABLE SECTION: Panel Position & Colors
HOW TO USE: Move or recolor the stats panel.
EXAMPLE:
  PANEL_POS = UDim2.fromScale(0.02, 0.02),  -- move to top-left
────────────────────────────────────────
]]
local BG_COLOR = Color3.fromRGB(25,25,40)
local TEXT_COLOR = Color3.fromRGB(255,255,255)
local TITLE_COLOR = Color3.fromRGB(255,215,0)
local STROKE_COLOR = Color3.fromRGB(80,120,255)
local PANEL_POS = UDim2.fromScale(0.78,0.02)
local PANEL_SIZE = UDim2.fromScale(0.20,0.20)

for _, c in ipairs(playerGui:GetChildren()) do if c.Name == "StatsGui" then c:Destroy() end end
local gui = Instance.new("ScreenGui")
gui.Name = "StatsGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 5; gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Size = PANEL_SIZE; panel.Position = PANEL_POS
panel.BackgroundColor3 = BG_COLOR; panel.BackgroundTransparency = 0.15
local pCorner = Instance.new("UICorner"); pCorner.CornerRadius = UDim.new(0.08,0); pCorner.Parent = panel
local pStroke = Instance.new("UIStroke"); pStroke.Thickness = 2; pStroke.Color = STROKE_COLOR; pStroke.Parent = panel; panel.Parent = gui

local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0.04,0); layout.HorizontalAlignment = Enum.HorizontalAlignment.Center; layout.Parent = panel
local function makeLabel()
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(0.92,0.18); lbl.Font = Enum.Font.GothamBold; lbl.TextScaled = true
	lbl.BackgroundTransparency = 1; lbl.TextColor3 = TEXT_COLOR; lbl.Parent = panel; return lbl
end
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.fromScale(0.92,0.2); titleLabel.Font = Enum.Font.GothamBlack; titleLabel.TextScaled = true
titleLabel.BackgroundTransparency = 1; titleLabel.TextColor3 = TITLE_COLOR; titleLabel.Text = "📊  STATS"; titleLabel.Parent = panel

local rollsLabel = makeLabel()
local rarestLabel = makeLabel()
local foundLabel = makeLabel()
local luckLabel = makeLabel()

local function update(stats)
	if not stats then return end
	rollsLabel.Text = "Rolls:  " .. tostring(stats.Rolls or 0)
	rarestLabel.Text = "Rarest: " .. tostring(stats.RarestAura or "None") .. "  (1 in " .. (stats.RarestRarity == 0 and "—" or stats.RarestRarity) .. ")"
	foundLabel.Text = "Found:  " .. tostring(stats.Found or 0) .. "/" .. tostring(stats.Total or 0)
	luckLabel.Text = "Luck:  ×" .. tostring(stats.Luck or 1)
end
task.delay(2, function() update(GetStatsFunction:InvokeServer()) end)
StatsUpdatedEvent.OnClientEvent:Connect(update)
]==]

-- ═══ 9) ADMIN UI ═══
ensure("LocalScript", "AdminUI", SPS).Source = [==[
--[[
═══════════════════════════════════════════════════════════
🛠️ ADMIN UI — Testing panel for admins only.
Sections: Weather Control, Give Mutated, Give Aura, Luck, Quick Actions.
Auto-reads weathers + mutations from WeatherData.
═══════════════════════════════════════════════════════════
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local AdminFunction = Remotes:WaitForChild("AdminFunction")
local AdminStatusEvent = Remotes:WaitForChild("AdminStatusEvent")
local AuraData = require(ReplicatedStorage:WaitForChild("AuraData"))
local WeatherData = require(ReplicatedStorage:WaitForChild("WeatherData"))

local function buildAdminUI()
	for _, c in ipairs(playerGui:GetChildren()) do if c.Name == "AdminPanelGui" then c:Destroy() end end
	local BG_COLOR = Color3.fromRGB(40,25,30)
	local TEXT_COLOR = Color3.fromRGB(255,255,255)
	local BUTTON_COLOR = Color3.fromRGB(200,60,80)
	local FIELD_COLOR = Color3.fromRGB(60,60,75)
	local SECTION_COLOR = Color3.fromRGB(80,120,255)
	local WEATHER_COLOR = Color3.fromRGB(80,160,255)
	local MUTATION_COLOR = Color3.fromRGB(180,100,255)

	local mutations = {}
	for _, w in ipairs(WeatherData.Weathers) do
		if w.Mutation and w.Mutation.Name then table.insert(mutations, { Name = w.Mutation.Name, Color = w.Mutation.Color }) end
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "AdminPanelGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 100; gui.Parent = playerGui

	local window = Instance.new("Frame")
	window.Size = UDim2.fromScale(0.30, 0.85); window.Position = UDim2.fromScale(0.35, 0.075)
	window.BackgroundColor3 = BG_COLOR; window.Visible = false
	local wCorner = Instance.new("UICorner"); wCorner.CornerRadius = UDim.new(0.04,0); wCorner.Parent = window
	local wStroke = Instance.new("UIStroke"); wStroke.Thickness = 2; wStroke.Color = BUTTON_COLOR; wStroke.Parent = window; window.Parent = gui

	local openBtn = Instance.new("TextButton")
	openBtn.Size = UDim2.fromScale(0.16,0.06); openBtn.Position = UDim2.fromScale(0.81,0.68)
	openBtn.Text = "🛠️  Admin"; openBtn.Font = Enum.Font.GothamBold; openBtn.TextScaled = true
	openBtn.BackgroundColor3 = BUTTON_COLOR; openBtn.TextColor3 = TEXT_COLOR
	local obCorner = Instance.new("UICorner"); obCorner.CornerRadius = UDim.new(0.15,0); obCorner.Parent = openBtn; openBtn.Parent = gui

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.fromScale(0.92, 0.88); scroll.Position = UDim2.fromScale(0.04, 0.08)
	scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 5
	scroll.CanvasSize = UDim2.fromScale(0,0); scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; scroll.Parent = window
	local list = Instance.new("UIListLayout"); list.Padding = UDim.new(0.012,0); list.Parent = scroll

	local function makeSection(text, color)
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(1, 0.035); lbl.Text = text; lbl.Font = Enum.Font.GothamBlack; lbl.TextScaled = true
		lbl.BackgroundColor3 = color or SECTION_COLOR; lbl.TextColor3 = TEXT_COLOR
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0.1,0); c.Parent = lbl; lbl.Parent = scroll
	end
	local function makeBtn(text, color, onClick)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.fromScale(1, 0.04); btn.Text = text; btn.Font = Enum.Font.GothamMedium; btn.TextScaled = true
		btn.BackgroundColor3 = color or FIELD_COLOR; btn.TextColor3 = TEXT_COLOR
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0.1,0); c.Parent = btn; btn.Parent = scroll
		if onClick then btn.MouseButton1Click:Connect(onClick) end
		return btn
	end

	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 0.04); title.Text = "🛠️  Admin Panel"
	title.Font = Enum.Font.GothamBlack; title.TextScaled = true
	title.BackgroundTransparency = 1; title.TextColor3 = TEXT_COLOR; title.Parent = scroll

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.fromScale(0.12, 0.035); closeBtn.Position = UDim2.fromScale(0.85, 0.01)
	closeBtn.Text = "✕"; closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextScaled = true
	closeBtn.BackgroundColor3 = Color3.fromRGB(80,30,40); closeBtn.TextColor3 = TEXT_COLOR; closeBtn.ZIndex = 10
	local cbCorner = Instance.new("UICorner"); cbCorner.CornerRadius = UDim.new(0.2,0); cbCorner.Parent = closeBtn; closeBtn.Parent = window

	makeSection("🌪️  WEATHER CONTROL", WEATHER_COLOR)
	for _, weather in ipairs(WeatherData.Weathers) do
		local btn = makeBtn("Set Weather: " .. weather.Name, FIELD_COLOR)
		btn.MouseButton1Click:Connect(function()
			local ok = AdminFunction:InvokeServer("ForceWeather", weather.Name)
			if ok then btn.Text = "✓ " .. weather.Name; task.wait(1); btn.Text = "Set Weather: " .. weather.Name end
		end)
	end

	makeSection("🧬  GIVE MUTATED AURA", MUTATION_COLOR)
	if #mutations > 0 then
		local mutLabel = Instance.new("TextLabel")
		mutLabel.Size = UDim2.fromScale(1, 0.025); mutLabel.Text = "Mutation: " .. mutations[1].Name
		mutLabel.Font = Enum.Font.GothamBold; mutLabel.TextScaled = true
		mutLabel.BackgroundTransparency = 1; mutLabel.TextColor3 = mutations[1].Color or TEXT_COLOR; mutLabel.Parent = scroll
		local currentMutIndex = 1
		makeBtn("← Switch Mutation →", FIELD_COLOR, function()
			currentMutIndex = currentMutIndex + 1
			if currentMutIndex > #mutations then currentMutIndex = 1 end
			mutLabel.Text = "Mutation: " .. mutations[currentMutIndex].Name
			mutLabel.TextColor3 = mutations[currentMutIndex].Color or TEXT_COLOR
		end)
		local sortedAuras = {}
		for _, a in ipairs(AuraData.Auras) do table.insert(sortedAuras, a) end
		table.sort(sortedAuras, function(a,b) return a.Rarity > b.Rarity end)
		for _, aura in ipairs(sortedAuras) do
			makeBtn("🧬 " .. aura.Name, MUTATION_COLOR, function()
				local stored = mutations[currentMutIndex].Name .. "|" .. aura.Name
				AdminFunction:InvokeServer("GiveMutated", stored)
			end)
		end
	else
		makeBtn("(No mutations — add weathers with mutations!)", FIELD_COLOR)
	end

	makeSection("✨  GIVE AURA", SECTION_COLOR)
	local sortedAuras2 = {}
	for _, a in ipairs(AuraData.Auras) do table.insert(sortedAuras2, a) end
	table.sort(sortedAuras2, function(a,b) return a.Rarity > b.Rarity end)
	for _, aura in ipairs(sortedAuras2) do
		local btn = makeBtn(aura.Name .. "  (1 in " .. aura.Rarity .. ")", FIELD_COLOR)
		btn.TextColor3 = aura.Color
		btn.MouseButton1Click:Connect(function()
			local ok = AdminFunction:InvokeServer("GiveAura", aura.Name)
			if ok then btn.Text = "✓ Given: " .. aura.Name; task.wait(0.8); btn.Text = aura.Name .. "  (1 in " .. aura.Rarity .. ")" end
		end)
	end

	makeSection("🍀  LUCK", SECTION_COLOR)
	local luckBox = Instance.new("TextBox")
	luckBox.Size = UDim2.fromScale(0.6, 0.04); luckBox.Text = "1"
	luckBox.Font = Enum.Font.GothamMedium; luckBox.TextScaled = true
	luckBox.BackgroundColor3 = FIELD_COLOR; luckBox.TextColor3 = TEXT_COLOR; luckBox.ClearTextOnFocus = false
	local lbCorner = Instance.new("UICorner"); lbCorner.CornerRadius = UDim.new(0.1,0); lbCorner.Parent = luckBox; luckBox.Parent = scroll
	makeBtn("Set Luck", BUTTON_COLOR, function()
		local val = tonumber(luckBox.Text) or 1
		local result = AdminFunction:InvokeServer("SetLuck", val)
		if result then luckBox.Text = tostring(result) end
	end)

	makeSection("⚡  QUICK ACTIONS", SECTION_COLOR)
	makeBtn("🎲 Give Rare", Color3.fromRGB(150,80,200), function() AdminFunction:InvokeServer("GiveRare") end)
	makeBtn("🗑️ Clear Inventory", Color3.fromRGB(200,60,60), function() AdminFunction:InvokeServer("ClearInventory") end)
	makeBtn("♻️ Reset ALL Data", Color3.fromRGB(180,40,40), function() AdminFunction:InvokeServer("ResetData") end)

	local isOpen = false
	openBtn.MouseButton1Click:Connect(function() isOpen = not isOpen; window.Visible = isOpen end)
	closeBtn.MouseButton1Click:Connect(function() isOpen = false; window.Visible = false end)
	print("🛠️ AdminUI v10 built!")
end
AdminStatusEvent.OnClientEvent:Connect(function(isAdmin) if isAdmin then buildAdminUI() end end)
]==]

print("══════════════════════════════════════")
print("✅ v10 UPDATE COMPLETE!")
print("══════════════════════════════════════")
print("📚 Teaching comments added to ALL scripts")
print("🌌 Skybox system added (add IDs to weather Skybox field)")
print("🌦️ Day/Night cycle added (configures in WeatherData.TimeCycle)")
print("📢 Dual announcements: UI banner + chat (both rarity-colored)")
print("══════════════════════════════════════")
print("📖 Read GUIDE_v10.md for full instructions!")
print("══════════════════════════════════════")
