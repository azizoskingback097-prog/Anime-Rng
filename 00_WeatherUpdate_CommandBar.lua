-- ═══════════════════════════════════════════════════════════
-- 🌪️  WEATHER UPDATE COMMAND BAR — adds weather + mutations + chat tips
-- ═══════════════════════════════════════════════════════════
-- HOW TO USE:  View > Command Bar  →  paste ALL of this  →  Enter
--
-- This is a PATCH (not a rebuild). It:
--   • Adds 2 new remotes (WeatherChangedEvent, ChatTipEvent)
--   • Adds CurrentWeather StringValue
--   • Creates WeatherData, WeatherServer, WeatherClient (NEW)
--   • Updates GameServer (adds mutation logic)
--   • Updates InventoryUI (shows mutated auras)
--   • Updates RollUI (shows mutation indicator on reveal)
--
-- Does NOT touch: AuraData, StatsUI, AdminUI (unchanged)
-- ═══════════════════════════════════════════════════════════

local RS  = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")

local function ensure(className, name, parent)
	local inst = parent:FindFirstChild(name)
	if inst and inst.ClassName ~= className then inst:Destroy(); inst = nil end
	if not inst then
		inst = Instance.new(className)
		inst.Name = name
		inst.Parent = parent
	end
	return inst
end

-- ═════ 1) NEW REMOTES ═════
local remotes = RS:FindFirstChild("Remotes") or ensure("Folder", "Remotes", RS)
ensure("RemoteEvent", "WeatherChangedEvent", remotes)
ensure("RemoteEvent", "ChatTipEvent", remotes)

-- ═════ 2) CURRENT WEATHER VALUE (read by GameServer for mutations) ═════
ensure("StringValue", "CurrentWeather", RS).Value = "Clear"

-- ═════ 3) WEATHER DATA (ModuleScript) ═════
ensure("ModuleScript", "WeatherData", RS).Source = [==[
local WeatherData = {}
WeatherData.Weathers = {
	{
		Name = "Clear", Weight = 50, Duration = { 90, 180 },
		Mutation = { Chance = 0, Name = nil, Color = nil },
		Lighting = { ClockTime = 14, FogColor = Color3.fromRGB(199,217,240), FogEnd = 100000,
			Ambient = Color3.fromRGB(128,128,128), OutdoorAmbient = Color3.fromRGB(128,128,128),
			Brightness = 2, ColorShift_Top = Color3.fromRGB(0,0,0), ColorShift_Bottom = Color3.fromRGB(0,0,0) },
		Skybox = nil, Particles = {},
		BannerText = "", BannerColor = Color3.fromRGB(255,255,255),
	},
	{
		Name = "Sandstorm", Weight = 25, Duration = { 60, 120 },
		Mutation = { Chance = 0.10, Name = "Sandy", Color = Color3.fromRGB(220,190,140) },
		Lighting = { ClockTime = 12, FogColor = Color3.fromRGB(200,170,120), FogEnd = 150,
			Ambient = Color3.fromRGB(180,150,100), OutdoorAmbient = Color3.fromRGB(200,170,120),
			Brightness = 1.5, ColorShift_Top = Color3.fromRGB(40,30,10), ColorShift_Bottom = Color3.fromRGB(40,30,10) },
		Skybox = nil,
		Particles = {
			{ Color = Color3.fromRGB(210,180,140),
			  Size = NumberSequence.new({ NumberSequenceKeypoint.new(0,4), NumberSequenceKeypoint.new(1,1) }),
			  Transparency = NumberSequence.new(0.4), Lifetime = NumberRange.new(4,7), Rate = 300,
			  Speed = NumberRange.new(15,30), SpreadAngle = Vector2.new(45,45),
			  Acceleration = Vector3.new(30,0,0), Texture = "" },
		},
		BannerText = "🌪️  SANDSTORM!  Auras have a 10% chance to be SANDY!",
		BannerColor = Color3.fromRGB(220,190,140),
	},
	{
		Name = "Blood Moon", Weight = 15, Duration = { 45, 90 },
		Mutation = { Chance = 0.08, Name = "Cursed", Color = Color3.fromRGB(150,0,30) },
		Lighting = { ClockTime = 0, FogColor = Color3.fromRGB(40,0,10), FogEnd = 300,
			Ambient = Color3.fromRGB(80,10,20), OutdoorAmbient = Color3.fromRGB(60,0,15),
			Brightness = 1, ColorShift_Top = Color3.fromRGB(60,0,0), ColorShift_Bottom = Color3.fromRGB(40,0,0) },
		Skybox = nil,
		Particles = {
			{ Color = Color3.fromRGB(200,30,30),
			  Size = NumberSequence.new({ NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,3) }),
			  Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0,0.8), NumberSequenceKeypoint.new(1,0) }),
			  Lifetime = NumberRange.new(5,10), Rate = 100, Speed = NumberRange.new(2,5),
			  SpreadAngle = Vector2.new(180,180), Acceleration = Vector3.new(0,-2,0), Texture = "" },
		},
		BannerText = "🔴  BLOOD MOON RISES!  Auras have an 8% chance to be CURSED!",
		BannerColor = Color3.fromRGB(200,30,30),
	},
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

-- ═════ 4) WEATHER SERVER (Script) ═════
ensure("Script", "WeatherServer", SSS).Source = [==[
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local WeatherData = require(ReplicatedStorage:WaitForChild("WeatherData"))

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

local function changeWeather()
	local weather = WeatherData.PickRandom()
	currentWeatherValue.Value = weather.Name
	WeatherChangedEvent:FireAllClients({
		Name = weather.Name, Lighting = weather.Lighting, Particles = weather.Particles,
		BannerText = weather.BannerText, BannerColor = weather.BannerColor,
	})
	if weather.Name ~= "Clear" then print("🌪️ Weather changed to: " .. weather.Name) end
end

-- chat tips loop (separate thread)
task.spawn(function()
	task.wait(START_DELAY)
	while true do
		local tip = TIPS[math.random(1, #TIPS)]
		for _, player in ipairs(Players:GetPlayers()) do
			ChatTipEvent:FireClient(player, tip)
		end
		task.wait(TIP_INTERVAL)
	end
end)

-- weather cycling loop
currentWeatherValue.Value = "Clear"
task.wait(START_DELAY)
while true do
	changeWeather()
	local weather = WeatherData.GetByName(currentWeatherValue.Value)
	local duration = math.random(weather.Duration[1], weather.Duration[2])
	task.wait(duration)
end
]==]

-- ═════ 5) WEATHER CLIENT (LocalScript) ═════
ensure("LocalScript", "WeatherClient", SPS).Source = [==[
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

local VFX_HEIGHT = 50
local TWEEN_TIME = 3
local BANNER_DURATION = 5
local TIP_COLOR = Color3.fromRGB(255, 215, 0)

local gui = Instance.new("ScreenGui")
gui.Name = "WeatherGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 15
for _, child in ipairs(playerGui:GetChildren()) do
	if child.Name == "WeatherGui" and child ~= gui then child:Destroy() end
end
gui.Parent = playerGui

local banner = Instance.new("TextLabel")
banner.Size = UDim2.fromScale(0.7, 0.08)
banner.Position = UDim2.fromScale(0.15, 0.04)
banner.Text = ""
banner.Font = Enum.Font.GothamBlack
banner.TextScaled = true
banner.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
banner.TextColor3 = Color3.fromRGB(255, 255, 255)
banner.BackgroundTransparency = 1
banner.Visible = false
local bnCorner = Instance.new("UICorner"); bnCorner.CornerRadius = UDim.new(0.15, 0); bnCorner.Parent = banner
banner.Parent = gui

local currentVFX = nil
local function clearVFX()
	if currentVFX then currentVFX:Destroy(); currentVFX = nil end
end
local function applyVFX(particles)
	clearVFX()
	if not particles or #particles == 0 then return end
	local character = player.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	currentVFX = Instance.new("Part")
	currentVFX.Name = "WeatherVFX"
	currentVFX.Size = Vector3.new(1, 1, 1)
	currentVFX.Transparency = 1
	currentVFX.CanCollide = false
	currentVFX.CanQuery = false
	currentVFX.Anchored = false
	currentVFX.Massless = true
	local weld = Instance.new("Weld")
	weld.Part0 = root
	weld.Part1 = currentVFX
	weld.C0 = CFrame.new(0, VFX_HEIGHT, 0)
	weld.Parent = currentVFX
	currentVFX.Parent = character
	for _, cfg in ipairs(particles) do
		local emitter = Instance.new("ParticleEmitter")
		emitter.Color = ColorSequence.new(cfg.Color or Color3.fromRGB(255,255,255))
		emitter.Size = cfg.Size or NumberSequence.new(2)
		emitter.Transparency = cfg.Transparency or NumberSequence.new(0)
		emitter.Lifetime = cfg.Lifetime or NumberRange.new(5, 10)
		emitter.Rate = cfg.Rate or 100
		emitter.Speed = cfg.Speed or NumberRange.new(5, 10)
		emitter.SpreadAngle = cfg.SpreadAngle or Vector2.new(45, 45)
		emitter.Acceleration = cfg.Acceleration or Vector3.new(0, 0, 0)
		if cfg.Texture and cfg.Texture ~= "" then emitter.Texture = cfg.Texture end
		emitter.Parent = currentVFX
	end
end

local function applyLighting(lightingCfg)
	if not lightingCfg then return end
	local tweenInfo = TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	TweenService:Create(Lighting, tweenInfo, {
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
	banner.Text = text
	banner.TextColor3 = color or Color3.fromRGB(255,255,255)
	banner.Visible = true
	banner.BackgroundTransparency = 0.3
	banner.TextTransparency = 0
	banner.Position = UDim2.fromScale(0.15, -0.1)
	TweenService:Create(banner, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.fromScale(0.15, 0.04) }):Play()
	task.delay(BANNER_DURATION, function()
		TweenService:Create(banner, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
			{ BackgroundTransparency = 1, TextTransparency = 1 }):Play()
		task.wait(0.5)
		banner.Visible = false
	end)
end

WeatherChangedEvent.OnClientEvent:Connect(function(info)
	applyLighting(info.Lighting)
	applyVFX(info.Particles)
	showBanner(info.BannerText, info.BannerColor)
end)

player.CharacterAdded:Connect(function()
	task.wait(1)
	local cv = ReplicatedStorage:FindFirstChild("CurrentWeather")
	if cv and cv.Value ~= "Clear" then
		local WeatherData = require(ReplicatedStorage:WaitForChild("WeatherData"))
		local weather = WeatherData.GetByName(cv.Value)
		if weather then applyVFX(weather.Particles) end
	end
end)

ChatTipEvent.OnClientEvent:Connect(function(message)
	pcall(function()
		StarterGui:SetCore("ChatMakeSystemMessage", {
			Text = message, Color = TIP_COLOR, Font = Enum.Font.SourceSansBold, TextSize = 18,
		})
	end)
end)
print("🌪️ WeatherClient loaded!")
]==]

-- ═════ 6) GAME SERVER (UPDATED — adds mutation logic!) ═════
ensure("Script", "GameServer", SSS).Source = [==[
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local AuraData = require(ReplicatedStorage:WaitForChild("AuraData"))

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

RollFunction.OnServerInvoke = function(player)
	local now = os.clock()
	if lastRoll[player] and (now - lastRoll[player]) < ROLL_COOLDOWN then return nil end
	lastRoll[player] = now
	local data = getData(player)
	data.Rolls = data.Rolls + 1
	local aura = AuraData.GetWeightedRandom(data.Luck)

	-- 🧬 MUTATION CHECK: does the current weather allow mutations?
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
				-- MUTATION APPLIED! Store as "Sandy|Tempest" format
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

GetInventoryFunction.OnServerInvoke = function(player)
	local data = getData(player)
	local counts = {}
	for _, name in ipairs(data.Inventory) do counts[name] = (counts[name] or 0) + 1 end
	return { Counts = counts, Equipped = data.Equipped }
end
EquipFunction.OnServerInvoke = function(player, auraName)
	local data = getData(player)
	for _, name in ipairs(data.Inventory) do
		if name == auraName then data.Equipped = auraName; return true end
	end
	return false
end
AdminFunction.OnServerInvoke = function(player, action, value)
	if not isAdmin(player) then return nil end
	local data = getData(player)
	if action == "GiveAura" then
		local aura = AuraData.GetByName(value)
		if not aura then return false end
		table.insert(data.Inventory, aura.Name)
		StatsUpdatedEvent:FireClient(player, buildStats(data))
		return true
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
print("✅ GameServer running! (Rolling + Inventory + Equip + Admin + Stats + DataStore + Mutations)")
]==]

-- ═════ 7) INVENTORY UI (UPDATED — shows mutated auras!) ═════
ensure("LocalScript", "InventoryUI", SPS).Source = [==[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetInventoryFunction = Remotes:WaitForChild("GetInventoryFunction")
local EquipFunction = Remotes:WaitForChild("EquipFunction")
local AuraData = require(ReplicatedStorage:WaitForChild("AuraData"))

local BG_COLOR = Color3.fromRGB(25,25,40)
local ITEM_COLOR = Color3.fromRGB(45,45,65)
local MUTATION_ITEM_COLOR = Color3.fromRGB(60,40,70)
local TEXT_COLOR = Color3.fromRGB(255,255,255)
local EQUIPPED_COLOR = Color3.fromRGB(80,200,120)
local BUTTON_COLOR = Color3.fromRGB(80,120,255)

local gui = Instance.new("ScreenGui")
gui.Name = "InventoryGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 20
for _, child in ipairs(playerGui:GetChildren()) do
	if child.Name == "InventoryGui" and child ~= gui then child:Destroy() end
end
gui.Parent = playerGui

local openBtn = Instance.new("TextButton")
openBtn.Size = UDim2.fromScale(0.16,0.06)
openBtn.Position = UDim2.fromScale(0.81,0.76)
openBtn.Text = "🎒  Inventory"
openBtn.Font = Enum.Font.GothamBold
openBtn.TextScaled = true
openBtn.BackgroundColor3 = BUTTON_COLOR
openBtn.TextColor3 = TEXT_COLOR
local obCorner = Instance.new("UICorner"); obCorner.CornerRadius = UDim.new(0.15,0); obCorner.Parent = openBtn
openBtn.Parent = gui

local window = Instance.new("Frame")
window.Size = UDim2.fromScale(0.55,0.62)
window.Position = UDim2.fromScale(0.225,0.19)
window.BackgroundColor3 = BG_COLOR
window.Visible = false
local wCorner = Instance.new("UICorner"); wCorner.CornerRadius = UDim.new(0.04,0); wCorner.Parent = window
local wStroke = Instance.new("UIStroke"); wStroke.Thickness = 2; wStroke.Color = Color3.fromRGB(80,120,255); wStroke.Parent = window
window.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.fromScale(1,0.1)
title.Position = UDim2.fromScale(0,0.02)
title.Text = "🎒  Your Auras"
title.Font = Enum.Font.GothamBlack
title.TextScaled = true
title.BackgroundTransparency = 1
title.TextColor3 = TEXT_COLOR
title.Parent = window

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromScale(0.07,0.09)
closeBtn.Position = UDim2.fromScale(0.9,0.015)
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextScaled = true
closeBtn.BackgroundColor3 = Color3.fromRGB(200,60,60)
closeBtn.TextColor3 = TEXT_COLOR
local cbCorner = Instance.new("UICorner"); cbCorner.CornerRadius = UDim.new(0.2,0); cbCorner.Parent = closeBtn
closeBtn.Parent = window

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.fromScale(0.94,0.82)
scroll.Position = UDim2.fromScale(0.03,0.13)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 6
scroll.CanvasSize = UDim2.fromScale(0,0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = window

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.fromScale(0.23,0.18)
grid.CellPadding = UDim2.fromScale(0.02,0.02)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = scroll

-- 🧬 helper: parse "Sandy|Tempest" → { Mutation = "Sandy", Base = "Tempest", Display = "Sandy Tempest" }
local function parseAuraName(stored)
	local sep = string.find(stored, "|")
	if sep then
		return {
			Mutation = string.sub(stored, 1, sep - 1),
			Base = string.sub(stored, sep + 1),
			Display = string.sub(stored, 1, sep - 1) .. " " .. string.sub(stored, sep + 1),
		}
	end
	return { Mutation = nil, Base = stored, Display = stored }
end

-- get mutation color from WeatherData
local function getMutationColor(mutationName)
	local WeatherData = require(ReplicatedStorage:WaitForChild("WeatherData"))
	local weather = WeatherData.GetByMutation(mutationName)
	if weather and weather.Mutation and weather.Mutation.Color then
		return weather.Mutation.Color
	end
	return nil
end

local isOpen = false
local function refresh()
	for _, child in ipairs(scroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
	local data = GetInventoryFunction:InvokeServer()
	if not data or not data.Counts then return end
	local equipped = data.Equipped
	local names = {}
	for name in pairs(data.Counts) do table.insert(names, name) end
	-- sort: mutated first, then by rarity
	table.sort(names, function(a, b)
		local pa = parseAuraName(a)
		local pb = parseAuraName(b)
		local ra = AuraData.GetByName(pa.Base)
		local rb = AuraData.GetByName(pb.Base)
		local raVal = (ra and ra.Rarity or 0)
		local rbVal = (rb and rb.Rarity or 0)
		-- mutated auras sort above non-mutated of same rarity
		if raVal == rbVal then
			if pa.Mutation and not pb.Mutation then return true end
			if not pa.Mutation and pb.Mutation then return false end
		end
		return raVal > rbVal
	end)
	for _, name in ipairs(names) do
		local parsed = parseAuraName(name)
		local aura = AuraData.GetByName(parsed.Base)
		local count = data.Counts[name]
		local item = Instance.new("TextButton")
		item.Text = parsed.Display .. "\n(×" .. count .. ")"
		item.Font = Enum.Font.GothamBold
		item.TextScaled = true
		-- mutated items get a different background + mutation color
		if parsed.Mutation then
			item.BackgroundColor3 = MUTATION_ITEM_COLOR
			local mutColor = getMutationColor(parsed.Mutation)
			item.TextColor3 = mutColor or (aura and aura.Color) or TEXT_COLOR
		else
			item.BackgroundColor3 = ITEM_COLOR
			item.TextColor3 = (aura and aura.Color) or TEXT_COLOR
		end
		if name == equipped then
			item.BackgroundColor3 = EQUIPPED_COLOR
			item.Text = "✓ " .. parsed.Display .. "\n(×" .. count .. ")"
			local eStroke = Instance.new("UIStroke"); eStroke.Thickness = 3; eStroke.Color = Color3.fromRGB(255,255,255); eStroke.Parent = item
		end
		local iCorner = Instance.new("UICorner"); iCorner.CornerRadius = UDim.new(0.15,0); iCorner.Parent = item
		item.Parent = scroll
		item.MouseButton1Click:Connect(function() EquipFunction:InvokeServer(name); refresh() end)
	end
end
openBtn.MouseButton1Click:Connect(function() isOpen = not isOpen; window.Visible = isOpen; if isOpen then refresh() end end)
closeBtn.MouseButton1Click:Connect(function() isOpen = false; window.Visible = false end)
]==]

-- ═════ 8) ROLL UI (UPDATED — shows mutation indicator!) ═════
ensure("LocalScript", "RollUI", SPS).Source = [==[
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

for _, child in ipairs(playerGui:GetChildren()) do
	if child.Name == "RollGui" then child:Destroy() end
end

local TEXT_COLOR = Color3.fromRGB(255,255,255)
local BANNER_COLOR = Color3.fromRGB(255,215,0)
local THEME_COLOR = Color3.fromRGB(30,30,45)
local ROLL_BUTTON_COLOR = Color3.fromRGB(80,120,255)
local MUTATION_COLOR = Color3.fromRGB(180, 100, 255)
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

local gui = Instance.new("ScreenGui")
gui.Name = "RollGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10
gui.Parent = playerGui

local button = Instance.new("TextButton")
button.Size = UDim2.fromScale(0.16,0.09)
button.Position = UDim2.fromScale(0.81,0.87)
button.Text = "ROLL"
button.Font = Enum.Font.GothamBlack
button.TextScaled = true
button.BackgroundColor3 = ROLL_BUTTON_COLOR
button.TextColor3 = TEXT_COLOR
local bCorner = Instance.new("UICorner"); bCorner.CornerRadius = UDim.new(0.12,0); bCorner.Parent = button
button.Parent = gui

local result = Instance.new("TextLabel")
result.Size = UDim2.fromScale(0.6,0.22)
result.Position = RESULT_HOME
result.Text = "Press ROLL to begin!"
result.Font = Enum.Font.GothamBlack
result.TextScaled = true
result.BackgroundTransparency = 1
result.TextColor3 = TEXT_COLOR
result.TextStrokeTransparency = 1
result.Parent = gui

local banner = Instance.new("TextLabel")
banner.Size = UDim2.fromScale(0.7,0.1)
banner.Position = UDim2.fromScale(0.15,0.12)
banner.Text = ""
banner.Font = Enum.Font.GothamBlack
banner.TextScaled = true
banner.BackgroundColor3 = THEME_COLOR
banner.TextColor3 = BANNER_COLOR
banner.BackgroundTransparency = 1
banner.Visible = false
local bnCorner = Instance.new("UICorner"); bnCorner.CornerRadius = UDim.new(0.2,0); bnCorner.Parent = banner
banner.Parent = gui

local flash = Instance.new("Frame")
flash.Size = UDim2.fromScale(1,1)
flash.Position = UDim2.fromScale(0,0)
flash.BackgroundColor3 = Color3.fromRGB(255,255,255)
flash.BackgroundTransparency = 1
flash.ZIndex = 50
flash.Parent = gui

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
	-- 🧬 show mutation indicator if mutated
	local displayText = res.DisplayName or res.Name
	if res.Mutated then
		displayText = "✨ MUTATED ✨\n" .. displayText
	end
	result.Text = displayText .. "\n1 in " .. res.Rarity .. "  •  " .. res.Tier
	result.TextColor3 = res.Color or TEXT_COLOR
	result.Position = UDim2.fromScale(0.2,-0.3)
	TweenService:Create(flash, TweenInfo.new(FLASH_TIME), {BackgroundTransparency = 1}):Play()
	local reveal = TweenService:Create(result, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = RESULT_HOME})
	reveal:Play(); reveal.Completed:Wait()
	if res.Rarity >= SHAKE_THRESHOLD or res.Mutated then
		setGlow(true); shakeLabel(result, RESULT_HOME, res.Rarity)
	end
	isRolling = false
end)

AnnounceEvent.OnClientEvent:Connect(function(info)
	local prefix = info.Mutated and "✨ MUTATED " or ""
	banner.Text = "🎉  " .. info.Player .. " pulled " .. prefix .. info.Name .. "  (1 in " .. info.Rarity .. ")!"
	banner.Visible = true; banner.BackgroundTransparency = 0.3; banner.Position = UDim2.fromScale(0.15,-0.15)
	TweenService:Create(banner, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.15,0.12)}):Play()
	task.delay(5, function() banner.Visible = false end)
end)
]==]

print("══════════════════════════════════════")
print("✅ WEATHER + MUTATION + CHAT TIPS DEPLOYED!")
print("══════════════════════════════════════")
print("🌪️ New scripts: WeatherData, WeatherServer, WeatherClient")
print("🧬 Updated: GameServer (mutations), InventoryUI (mutation display), RollUI (mutation indicator)")
print("💬 Chat tips will appear every 60 seconds")
print("📅 Weather changes every 1-3 minutes (Clear / Sandstorm / Blood Moon)")
print("══════════════════════════════════════")
