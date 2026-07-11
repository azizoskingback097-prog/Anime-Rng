-- ═══════════════════════════════════════════════════════════
-- 🛠️  v9 ADMIN WEATHER UPDATE — patch GameServer + WeatherServer + AdminUI
-- ═══════════════════════════════════════════════════════════
-- HOW TO USE:  View > Command Bar  →  paste ALL of this  →  Enter
--
-- Updates:
--   • GameServer    → adds ForceWeather + GiveMutated + GetWeatherList actions
--   • WeatherServer → detects admin-forced weather changes (resets timer)
--   • AdminUI       → adds WEATHER CONTROL + GIVE MUTATED AURA sections
--
-- Does NOT touch: AuraData, WeatherData, WeatherClient, RollUI, InventoryUI, StatsUI
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

-- ═════ 1) GAME SERVER (updated with ForceWeather + GiveMutated) ═════
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
	if action == "IsAdmin" then return true
	elseif action == "GiveAura" then
		local aura = AuraData.GetByName(value)
		if not aura then return false end
		table.insert(data.Inventory, aura.Name)
		StatsUpdatedEvent:FireClient(player, buildStats(data))
		return true
	elseif action == "GiveMutated" then
		table.insert(data.Inventory, value)
		StatsUpdatedEvent:FireClient(player, buildStats(data))
		return true
	elseif action == "ForceWeather" then
		local WeatherData = require(ReplicatedStorage:WaitForChild("WeatherData"))
		local weather = WeatherData.GetByName(value)
		if not weather then return false end
		currentWeatherValue.Value = weather.Name
		WeatherChangedEvent:FireAllClients({
			Name = weather.Name, Lighting = weather.Lighting, Particles = weather.Particles,
			BannerText = weather.BannerText, BannerColor = weather.BannerColor,
		})
		print("🛠️ Admin forced weather: " .. weather.Name)
		return true
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
print("✅ GameServer v9 running!")
]==]

-- ═════ 2) WEATHER SERVER (updated — detects admin forcing) ═════
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

local function applyWeather(weather)
	currentWeatherValue.Value = weather.Name
	WeatherChangedEvent:FireAllClients({
		Name = weather.Name, Lighting = weather.Lighting, Particles = weather.Particles,
		BannerText = weather.BannerText, BannerColor = weather.BannerColor,
	})
	if weather.Name ~= "Clear" then print("🌪️ Weather: " .. weather.Name) end
end

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

currentWeatherValue.Value = "Clear"
task.wait(START_DELAY)
while true do
	local weather = WeatherData.PickRandom()
	applyWeather(weather)
	local duration = math.random(weather.Duration[1], weather.Duration[2])
	local appliedName = weather.Name
	local elapsed = 0
	while elapsed < duration do
		task.wait(1)
		elapsed = elapsed + 1
		if currentWeatherValue.Value ~= appliedName then
			appliedName = currentWeatherValue.Value
			local forced = WeatherData.GetByName(appliedName)
			if forced then duration = math.random(forced.Duration[1], forced.Duration[2]) end
			elapsed = 0
		end
	end
end
]==]

-- ═════ 3) ADMIN UI (updated — weather control + mutated section) ═════
ensure("LocalScript", "AdminUI", SPS).Source = [==[
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
	for _, child in ipairs(playerGui:GetChildren()) do
		if child.Name == "AdminPanelGui" then child:Destroy() end
	end

	local BG_COLOR = Color3.fromRGB(40,25,30)
	local TEXT_COLOR = Color3.fromRGB(255,255,255)
	local BUTTON_COLOR = Color3.fromRGB(200,60,80)
	local FIELD_COLOR = Color3.fromRGB(60,60,75)
	local SECTION_COLOR = Color3.fromRGB(80,120,255)
	local WEATHER_COLOR = Color3.fromRGB(80,160,255)
	local MUTATION_COLOR = Color3.fromRGB(180,100,255)

	local mutations = {}
	for _, w in ipairs(WeatherData.Weathers) do
		if w.Mutation and w.Mutation.Name then
			table.insert(mutations, { Name = w.Mutation.Name, Color = w.Mutation.Color })
		end
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "AdminPanelGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 100; gui.Parent = playerGui

	local window = Instance.new("Frame")
	window.Size = UDim2.fromScale(0.30, 0.85); window.Position = UDim2.fromScale(0.35, 0.075)
	window.BackgroundColor3 = BG_COLOR; window.Visible = false
	local wCorner = Instance.new("UICorner"); wCorner.CornerRadius = UDim.new(0.04,0); wCorner.Parent = window
	local wStroke = Instance.new("UIStroke"); wStroke.Thickness = 2; wStroke.Color = BUTTON_COLOR; wStroke.Parent = window
	window.Parent = gui

	local openBtn = Instance.new("TextButton")
	openBtn.Size = UDim2.fromScale(0.16,0.06); openBtn.Position = UDim2.fromScale(0.81,0.68)
	openBtn.Text = "🛠️  Admin"; openBtn.Font = Enum.Font.GothamBold; openBtn.TextScaled = true
	openBtn.BackgroundColor3 = BUTTON_COLOR; openBtn.TextColor3 = TEXT_COLOR
	local obCorner = Instance.new("UICorner"); obCorner.CornerRadius = UDim.new(0.15,0); obCorner.Parent = openBtn
	openBtn.Parent = gui

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.fromScale(0.92, 0.88); scroll.Position = UDim2.fromScale(0.04, 0.08)
	scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 5
	scroll.CanvasSize = UDim2.fromScale(0,0); scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = window

	local list = Instance.new("UIListLayout"); list.Padding = UDim.new(0.012,0); list.Parent = scroll

	local function makeSection(text, color)
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(1, 0.035); lbl.Text = text
		lbl.Font = Enum.Font.GothamBlack; lbl.TextScaled = true
		lbl.BackgroundColor3 = color or SECTION_COLOR; lbl.TextColor3 = TEXT_COLOR
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0.1,0); c.Parent = lbl
		lbl.Parent = scroll
		return lbl
	end

	local function makeBtn(text, color, onClick)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.fromScale(1, 0.04); btn.Text = text
		btn.Font = Enum.Font.GothamMedium; btn.TextScaled = true
		btn.BackgroundColor3 = color or FIELD_COLOR; btn.TextColor3 = TEXT_COLOR
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0.1,0); c.Parent = btn
		btn.Parent = scroll
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
	local cbCorner = Instance.new("UICorner"); cbCorner.CornerRadius = UDim.new(0.2,0); cbCorner.Parent = closeBtn
	closeBtn.Parent = window

	-- 🌪️ WEATHER CONTROL
	makeSection("🌪️  WEATHER CONTROL", WEATHER_COLOR)
	for _, weather in ipairs(WeatherData.Weathers) do
		local btn = makeBtn("Set Weather: " .. weather.Name, FIELD_COLOR)
		btn.MouseButton1Click:Connect(function()
			local ok = AdminFunction:InvokeServer("ForceWeather", weather.Name)
			if ok then btn.Text = "✓ " .. weather.Name; task.wait(1); btn.Text = "Set Weather: " .. weather.Name end
		end)
	end

	-- 🧬 GIVE MUTATED AURA
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
				local mutName = mutations[currentMutIndex].Name
				local stored = mutName .. "|" .. aura.Name
				AdminFunction:InvokeServer("GiveMutated", stored)
			end)
		end
	else
		makeBtn("(No mutations — add weathers with mutations!)", FIELD_COLOR)
	end

	-- GIVE NORMAL AURA
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

	-- LUCK
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

	-- QUICK ACTIONS
	makeSection("⚡  QUICK ACTIONS", SECTION_COLOR)
	makeBtn("🎲 Give Rare", Color3.fromRGB(150,80,200), function() AdminFunction:InvokeServer("GiveRare") end)
	makeBtn("🗑️ Clear Inventory", Color3.fromRGB(200,60,60), function() AdminFunction:InvokeServer("ClearInventory") end)
	makeBtn("♻️ Reset ALL Data", Color3.fromRGB(180,40,40), function() AdminFunction:InvokeServer("ResetData") end)

	local isOpen = false
	openBtn.MouseButton1Click:Connect(function() isOpen = not isOpen; window.Visible = isOpen end)
	closeBtn.MouseButton1Click:Connect(function() isOpen = false; window.Visible = false end)
	print("🛠️ AdminUI v9 built!")
end

AdminStatusEvent.OnClientEvent:Connect(function(isAdmin) if isAdmin then buildAdminUI() end end)
]==]

print("══════════════════════════════════════")
print("✅ v9 ADMIN WEATHER UPDATE DEPLOYED!")
print("══════════════════════════════════════")
print("🆕 Admin panel now has:")
print("   🌪️ Weather Control (force any weather instantly)")
print("   🧬 Give Mutated Aura (pick mutation + aura)")
print("📦 See GUIDE_Skybox_and_NewWeather.md for how to add skyboxes + new weathers!")
print("══════════════════════════════════════")
